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
      (_db.select(_accounts)
            ..where((a) => a.archivedAt.isNull())
            ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
          .watch()
          .map((rows) => rows.map(_toAccount).toList());

  /// Comptes archivés, du plus récemment archivé au plus ancien.
  Stream<List<Account>> watchArchived() =>
      (_db.select(_accounts)
            ..where((a) => a.archivedAt.isNotNull())
            ..orderBy([(a) => OrderingTerm.desc(a.archivedAt)]))
          .watch()
          .map((rows) => rows.map(_toAccount).toList());

  /// Un compte, ou `null` s'il n'existe pas (ou plus).
  Stream<Account?> watchById(String id) =>
      (_db.select(_accounts)..where((a) => a.id.equals(id)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _toAccount(row));

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
    return Ok(_toAccount(row));
  });

  Future<Result<Account>> update(String id, AccountDraft draft) =>
      _guard(() async {
        final errors = await _validate(draft, excludeId: id);
        if (errors.isNotEmpty) return Err(ValidationFailure(errors));

        final rows =
            await (_db.update(_accounts)..where((a) => a.id.equals(id)))
                .writeReturning(
                  AccountsCompanion(
                    name: Value(draft.normalizedName),
                    type: Value(draft.type!.storageValue),
                    openingBalance: Value(draft.openingBalance.value),
                    updatedAt: Value(_nowMs()),
                  ),
                );
        return rows.isEmpty
            ? const Err(NotFoundFailure())
            : Ok(_toAccount(rows.single));
      });

  Future<Result<void>> archive(String id) => _guard(() async {
    final now = _nowMs();
    final count =
        await (_db.update(_accounts)
              ..where((a) => a.id.equals(id) & a.archivedAt.isNull()))
            .write(
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

  static Account _toAccount(AccountRow row) {
    final opening = Money(row.openingBalance);
    return Account(
      id: row.id,
      name: row.name,
      type: AccountType.fromStorage(row.type),
      openingBalance: opening,
      // Pas encore de mouvements : la fonctionnalité Transactions ajoutera
      // ici la somme des opérations du compte.
      balance: opening,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      archivedAt: row.archivedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!, isUtc: true),
    );
  }
}
