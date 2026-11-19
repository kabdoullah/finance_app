import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/result.dart';
import '../../../core/money/money.dart';
import '../domain/account.dart';
import '../domain/account_draft.dart';
import '../domain/account_type.dart';

/// Accès aux comptes. Seul endroit où le solde d'un compte est calculé.
class AccountsRepository {
  AccountsRepository(this._db, this._clock, {String Function()? newId})
    : _newId = newId ?? const Uuid().v4;

  final AppDatabase _db;
  final Clock _clock;
  final String Function() _newId;

  $AccountsTable get _accounts => _db.accounts;

  /// Comptes actifs, du plus ancien au plus récent.
  Stream<List<Account>> watchActive() =>
      _watchAccounts('WHERE a.archived_at IS NULL ORDER BY a.created_at ASC');

  /// Comptes archivés, du plus récemment archivé au plus ancien.
  Stream<List<Account>> watchArchived() => _watchAccounts(
    'WHERE a.archived_at IS NOT NULL ORDER BY a.archived_at DESC',
  );

  /// Un compte, ou `null` s'il n'existe pas (ou plus).
  Stream<Account?> watchById(String id) => _watchAccounts('WHERE a.id = ?', [
    Variable.withString(id),
  ]).map((accounts) => accounts.isEmpty ? null : accounts.single);

  /// Lecture ponctuelle d'un compte avec son solde (sans abonnement).
  Future<Account?> getById(String id) async {
    return _selectAccounts('WHERE a.id = ?', [
      Variable.withString(id),
    ]).getSingleOrNull();
  }

  /// Le solde n'est jamais stocké : solde initial + revenus − dépenses
  /// − transferts sortants + transferts entrants. Réévalué à chaque
  /// changement des comptes ou des opérations.
  static const _accountsWithBalance = '''
SELECT a.*,
  a.opening_balance + COALESCE((
    SELECT SUM(CASE
      WHEN t.account_id = a.id AND t.kind = 'income' THEN t.amount
      WHEN t.account_id = a.id THEN -t.amount
      ELSE t.amount
    END)
    FROM transactions t WHERE t.account_id = a.id OR t.to_account_id = a.id
  ), 0) AS balance,
  (SELECT MAX(t.occurred_at) FROM transactions t
    WHERE t.account_id = a.id OR t.to_account_id = a.id) AS last_operation_at,
  (SELECT COUNT(*) FROM transactions t
    WHERE t.account_id = a.id OR t.to_account_id = a.id) AS operation_count
FROM accounts a
''';

  Stream<List<Account>> _watchAccounts(
    String clauses, [
    List<Variable<Object>> variables = const [],
  ]) => _selectAccounts(clauses, variables).watch();

  Selectable<Account> _selectAccounts(
    String clauses, [
    List<Variable<Object>> variables = const [],
  ]) => _db
      .customSelect(
        '$_accountsWithBalance $clauses',
        variables: variables,
        readsFrom: {_accounts, _db.transactions},
      )
      .map(
        (row) => _toAccount(
          _accounts.map(row.data),
          balance: Money(row.read<int>('balance')),
          lastOperationAtMs: row.readNullable<int>('last_operation_at'),
          operationCount: row.read<int>('operation_count'),
        ),
      );

  Future<Result<Account>> create(AccountDraft draft) => _guard(() async {
    final errors = await _validate(draft);
    if (errors.isNotEmpty) return Err(ValidationFailure(errors));

    final now = _nowMs();
    final row = await _accounts.insertReturning(
      AccountsCompanion.insert(
        id: _newId(),
        name: draft.normalizedName,
        type: draft.type!.storageValue,
        openingBalance: draft.openingBalance.value,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return Ok(await _reload(row.id));
  });

  /// Modifie le nom et le type. Le solde initial est figé à la création :
  /// celui du [draft] est ignoré.
  Future<Result<Account>> update(
    String id,
    AccountDraft draft,
  ) => _guard(() async {
    final errors = await _validate(draft, excludeId: id);
    if (errors.isNotEmpty) return Err(ValidationFailure(errors));

    final rows = await (_db.update(_accounts)..where((a) => a.id.equals(id)))
        .writeReturning(
          AccountsCompanion(
            name: Value(draft.normalizedName),
            type: Value(draft.type!.storageValue),
            updatedAt: Value(_nowMs()),
          ),
        );
    return rows.isEmpty ? const Err(NotFoundFailure()) : Ok(await _reload(id));
  });

  Future<Result<void>> archive(String id) => _guard(() async {
    final now = _nowMs();
    final count =
        await (_db.update(
          _accounts,
        )..where((a) => a.id.equals(id) & a.archivedAt.isNull())).write(
          AccountsCompanion(archivedAt: Value(now), updatedAt: Value(now)),
        );
    return count == 0 ? const Err(NotFoundFailure()) : const Ok(null);
  });

  /// Échoue avec [AccountFieldError.nameTaken] si un compte actif porte
  /// entre-temps le même nom.
  Future<Result<void>> restore(String id) => _guard(() async {
    final row = await (_db.select(
      _accounts,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    if (row == null || row.archivedAt == null) {
      return const Err(NotFoundFailure());
    }
    if (await _isNameTaken(row.name, excludeId: id)) {
      return const Err(ValidationFailure({AccountFieldError.nameTaken}));
    }
    await (_db.update(_accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        archivedAt: const Value(null),
        updatedAt: Value(_nowMs()),
      ),
    );
    return const Ok(null);
  });

  /// Suppression définitive. Les opérations du compte suivront par clé
  /// étrangère (ON DELETE CASCADE) quand la table des transactions existera.
  Future<Result<void>> delete(String id) => _guard(() async {
    final count = await (_db.delete(
      _accounts,
    )..where((a) => a.id.equals(id))).go();
    return count == 0 ? const Err(NotFoundFailure()) : const Ok(null);
  });

  Future<Set<AccountFieldError>> _validate(
    AccountDraft draft, {
    String? excludeId,
  }) async {
    final errors = draft.validate();
    if (!errors.contains(AccountFieldError.nameMissing) &&
        await _isNameTaken(draft.normalizedName, excludeId: excludeId)) {
      errors.add(AccountFieldError.nameTaken);
    }
    return errors;
  }

  /// Même règle que l'index `accounts_active_name_unique` : `lower()` SQLite.
  Future<bool> _isNameTaken(String name, {String? excludeId}) async {
    final query = _db.selectOnly(_accounts)
      ..addColumns([_accounts.id])
      ..where(
        _accounts.name.lower().equalsExp(Variable(name).lower()) &
            _accounts.archivedAt.isNull() &
            (excludeId == null
                ? const Constant(true)
                : _accounts.id.equals(excludeId).not()),
      )
      ..limit(1);
    return (await query.getSingleOrNull()) != null;
  }

  int _nowMs() => _clock().toUtc().millisecondsSinceEpoch;

  /// Convertit les erreurs SQLite inattendues en [StorageFailure].
  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      return Err(StorageFailure(error, stackTrace));
    }
  }

  static Account _toAccount(
    AccountRow row, {
    required Money balance,
    required int? lastOperationAtMs,
    required int operationCount,
  }) {
    DateTime? date(int? ms) => ms == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return Account(
      id: row.id,
      name: row.name,
      type: AccountType.fromStorage(row.type),
      openingBalance: Money(row.openingBalance),
      balance: balance,
      createdAt: date(row.createdAt)!,
      archivedAt: date(row.archivedAt),
      lastOperationAt: date(lastOperationAtMs),
      operationCount: operationCount,
    );
  }

  /// Relit un compte avec son solde calculé (après écriture).
  Future<Account> _reload(String id) async => (await watchById(id).first)!;
}
