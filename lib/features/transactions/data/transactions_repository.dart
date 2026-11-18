import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/result.dart';
import '../../../core/money/money.dart';
import '../../../core/time/month.dart';
import '../../categories/data/categories_repository.dart';
import '../domain/transaction.dart';
import '../domain/transaction_draft.dart';

/// Accès aux opérations (dépenses, revenus, transferts).
class TransactionsRepository {
  TransactionsRepository(this._db, this._clock, {String Function()? newId})
    : _newId = newId ?? const Uuid().v4;

  final AppDatabase _db;
  final Clock _clock;
  final String Function() _newId;

  late final _toAccounts = _db.alias(_db.accounts, 'to_account');
  late final _parents = _db.alias(_db.categories, 'parent_category');

  /// Opérations d'un mois, de la plus récente à la plus ancienne.
  Stream<List<Transaction>> watchMonth(Month month) => _watch(
    (t) => t.occurredAt.isBetweenValues(_ms(month.start), _ms(month.end) - 1),
  );

  /// Dernières opérations, tous mois confondus.
  Stream<List<Transaction>> watchRecent(int limit) =>
      _watch((t) => const Constant(true), limit: limit);

  /// Toutes les opérations qui touchent un compte (transferts compris).
  Stream<List<Transaction>> watchForAccount(String accountId) => _watch(
    (t) => t.accountId.equals(accountId) | t.toAccountId.equals(accountId),
  );

  Stream<Transaction?> watchById(String id) =>
      _query((t) => t.id.equals(id))
          .watchSingleOrNull()
          .map(_toTransactionOrNull);

  /// Vrai dès qu'au moins une opération existe.
  Stream<bool> watchHasAny() {
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([_db.transactions.id])
      ..limit(1);
    return query.watch().map((rows) => rows.isNotEmpty);
  }

  /// Compte de la dernière opération saisie, s'il est toujours actif.
  Future<String?> lastUsedAccountId() async {
    final query =
        _db.select(_db.transactions).join([
            innerJoin(
              _db.accounts,
              _db.accounts.id.equalsExp(_db.transactions.accountId),
            ),
          ])
          ..where(_db.accounts.archivedAt.isNull())
          ..orderBy([OrderingTerm.desc(_db.transactions.createdAt)])
          ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.readTable(_db.transactions).accountId;
  }

  Future<Result<Transaction>> create(
    TransactionDraft draft, {
    EntryMethod entryMethod = EntryMethod.manual,
    String? recurringId,
  }) => _guard(() async {
    final errors = await _validate(draft);
    if (errors.isNotEmpty) return Err(ValidationFailure(errors));
    final id = await _insert(draft, entryMethod, recurringId);
    return Ok((await _get(id))!);
  });

  /// Enregistre plusieurs opérations d'un coup (saisie rapide) : toutes ou
  /// aucune.
  Future<Result<List<Transaction>>> createAll(
    List<TransactionDraft> drafts, {
    required EntryMethod entryMethod,
  }) => _guard(() async {
    for (final draft in drafts) {
      final errors = await _validate(draft);
      if (errors.isNotEmpty) return Err(ValidationFailure(errors));
    }
    final ids = await _db.transaction(
      () async => [
        for (final draft in drafts) await _insert(draft, entryMethod, null),
      ],
    );
    return Ok([for (final id in ids) (await _get(id))!]);
  });

  Future<String> _insert(
    TransactionDraft draft,
    EntryMethod entryMethod,
    String? recurringId,
  ) async {
    final id = _newId();
    final now = _nowMs();
    await _db
        .into(_db.transactions)
        .insert(
          _companion(draft).copyWith(
            id: Value(id),
            entryMethod: Value(entryMethod.storageValue),
            recurringId: Value(recurringId),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return id;
  }

  Future<Result<Transaction>> update(String id, TransactionDraft draft) =>
      _guard(() async {
        final errors = await _validate(draft);
        if (errors.isNotEmpty) return Err(ValidationFailure(errors));

        final count =
            await (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
                .write(_companion(draft).copyWith(updatedAt: Value(_nowMs())));
        if (count == 0) return const Err(NotFoundFailure());
        return Ok((await _get(id))!);
      });

  /// Copie de l'opération, datée de maintenant.
  Future<Result<Transaction>> duplicate(String id) => _guard(() async {
    final original = await _get(id);
    if (original == null) return const Err(NotFoundFailure());
    return create(
      TransactionDraft.from(original).copyWith(occurredAt: _clock()),
      // Une copie d'une échéance récurrente est une saisie à la main.
      entryMethod: original.entryMethod == EntryMethod.recurring
          ? EntryMethod.manual
          : original.entryMethod,
    );
  });

  /// Supprime et retourne l'opération, pour pouvoir l'annuler ([restore]).
  Future<Result<Transaction>> delete(String id) => _guard(() async {
    final transaction = await _get(id);
    if (transaction == null) return const Err(NotFoundFailure());
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
    return Ok(transaction);
  });

  /// Annule une suppression : réinsère l'opération à l'identique.
  Future<Result<void>> restore(Transaction transaction) => _guard(() async {
    final now = _nowMs();
    // Le modèle récurrent a pu être supprimé entre-temps.
    final recurringId = transaction.recurringId;
    final keepsLink =
        recurringId != null &&
        await (_db.select(
              _db.recurringOperations,
            )..where((r) => r.id.equals(recurringId))).getSingleOrNull() !=
            null;
    await _db
        .into(_db.transactions)
        .insert(
          _companion(TransactionDraft.from(transaction)).copyWith(
            id: Value(transaction.id),
            entryMethod: Value(transaction.entryMethod.storageValue),
            recurringId: Value(keepsLink ? recurringId : null),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return const Ok(null);
  });

  TransactionsCompanion _companion(TransactionDraft draft) {
    final isTransfer = draft.kind == TransactionKind.transfer;
    return TransactionsCompanion(
      kind: Value(draft.kind.storageValue),
      amount: Value(draft.amount.value),
      accountId: Value(draft.accountId!),
      toAccountId: Value(isTransfer ? draft.toAccountId : null),
      categoryId: Value(isTransfer ? null : draft.categoryId),
      description: Value(draft.normalizedDescription),
      occurredAt: Value(_ms(draft.occurredAt)),
    );
  }

  Future<Set<TransactionFieldError>> _validate(TransactionDraft draft) async {
    final errors = draft.validate();

    for (final id in [
      draft.accountId,
      if (draft.kind == TransactionKind.transfer) draft.toAccountId,
    ]) {
      if (id != null && !await _isActiveAccount(id)) {
        errors.add(TransactionFieldError.accountUnavailable);
      }
    }

    final categoryKind = draft.kind.categoryKind;
    final categoryId = draft.categoryId;
    if (categoryKind != null && categoryId != null) {
      final row = await (_db.select(
        _db.categories,
      )..where((c) => c.id.equals(categoryId))).getSingleOrNull();
      if (row == null || row.kind != categoryKind.storageValue) {
        errors.add(TransactionFieldError.categoryInvalid);
      }
    }
    return errors;
  }

  Future<bool> _isActiveAccount(String id) async {
    final row = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(id) & a.archivedAt.isNull())).getSingleOrNull();
    return row != null;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _query(
    Expression<bool> Function($TransactionsTable t) filter, {
    int? limit,
  }) {
    final t = _db.transactions;
    final query =
        _db.select(t).join([
            innerJoin(_db.accounts, _db.accounts.id.equalsExp(t.accountId)),
            leftOuterJoin(_toAccounts, _toAccounts.id.equalsExp(t.toAccountId)),
            leftOuterJoin(
              _db.categories,
              _db.categories.id.equalsExp(t.categoryId),
            ),
            leftOuterJoin(
              _parents,
              _parents.id.equalsExp(_db.categories.parentId),
            ),
          ])
          ..where(filter(t))
          ..orderBy([
            OrderingTerm.desc(t.occurredAt),
            OrderingTerm.desc(t.createdAt),
          ]);
    if (limit != null) query.limit(limit);
    return query;
  }

  Stream<List<Transaction>> _watch(
    Expression<bool> Function($TransactionsTable t) filter, {
    int? limit,
  }) => _query(
    filter,
    limit: limit,
  ).watch().map((rows) => rows.map(_toTransaction).toList());

  Future<Transaction?> _get(String id) async => _toTransactionOrNull(
    await _query((t) => t.id.equals(id)).getSingleOrNull(),
  );

  Transaction? _toTransactionOrNull(TypedResult? row) =>
      row == null ? null : _toTransaction(row);

  Transaction _toTransaction(TypedResult row) {
    final t = row.readTable(_db.transactions);
    final category = row.readTableOrNull(_db.categories);
    final parent = row.readTableOrNull(_parents);
    return Transaction(
      id: t.id,
      kind: TransactionKind.fromStorage(t.kind),
      amount: Money(t.amount),
      accountId: t.accountId,
      accountName: row.readTable(_db.accounts).name,
      toAccountId: t.toAccountId,
      toAccountName: row.readTableOrNull(_toAccounts)?.name,
      category: category == null
          ? null
          : CategoriesRepository.toCategory(category),
      parentCategory: parent == null
          ? null
          : CategoriesRepository.toCategory(parent),
      description: t.description,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        t.occurredAt,
        isUtc: true,
      ),
      entryMethod: EntryMethod.fromStorage(t.entryMethod),
      recurringId: t.recurringId,
    );
  }

  int _nowMs() => _ms(_clock());

  static int _ms(DateTime date) => date.toUtc().millisecondsSinceEpoch;

  /// Convertit les erreurs SQLite inattendues en [StorageFailure].
  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      return Err(StorageFailure(error, stackTrace));
    }
  }
}
