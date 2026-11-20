import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/result.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../categories/data/categories_repository.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_draft.dart';
import '../domain/planned_draft.dart';
import '../domain/planned_expense.dart';

/// Dépenses planifiées encore à payer, et leur paiement.
class PlannedRepository {
  PlannedRepository(
    this._db,
    this._clock,
    this._transactions, {
    String Function()? newId,
  }) : _newId = newId ?? const Uuid().v4;

  final AppDatabase _db;
  final Clock _clock;
  final TransactionsRepository _transactions;
  final String Function() _newId;

  $PlannedExpensesTable get _table => _db.plannedExpenses;
  late final _parents = _db.alias(_db.categories, 'parent');

  /// Toutes les dépenses à payer, de la plus ancienne date prévue à la plus
  /// lointaine.
  Stream<List<PlannedExpense>> watchAll() =>
      _query().watch().map((rows) => rows.map(_toExpense).toList());

  Stream<PlannedExpense?> watchById(String id) =>
      (_query()..where(_table.id.equals(id))).watchSingleOrNull().map(
        (row) => row == null ? null : _toExpense(row),
      );

  Future<PlannedExpense?> get(String id) async {
    final row = await (_query()..where(_table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toExpense(row);
  }

  Future<Result<PlannedExpense>> create(PlannedDraft draft) => _guard(() async {
    final errors = await _validate(draft);
    if (errors.isNotEmpty) return Err(ValidationFailure(errors));
    final id = _newId();
    final now = _nowMs();
    await _table.insertOne(
      _companion(
        draft,
      ).copyWith(id: Value(id), createdAt: Value(now), updatedAt: Value(now)),
    );
    return Ok((await get(id))!);
  });

  Future<Result<PlannedExpense>> update(String id, PlannedDraft draft) =>
      _guard(() async {
        final current = await get(id);
        if (current == null) return const Err(NotFoundFailure());
        final errors = await _validate(draft, keptDue: current.dueDate);
        if (errors.isNotEmpty) return Err(ValidationFailure(errors));
        await (_db.update(_table)..where((p) => p.id.equals(id))).write(
          _companion(draft).copyWith(updatedAt: Value(_nowMs())),
        );
        return Ok((await get(id))!);
      });

  /// Supprime et retourne la dépense, pour pouvoir l'annuler ([restore]).
  Future<Result<PlannedExpense>> delete(String id) => _guard(() async {
    final expense = await get(id);
    if (expense == null) return const Err(NotFoundFailure());
    await (_db.delete(_table)..where((p) => p.id.equals(id))).go();
    return Ok(expense);
  });

  /// Annule une suppression : réinsère la dépense à l'identique.
  Future<Result<void>> restore(PlannedExpense expense) => _guard(() async {
    await _table.insertOne(
      PlannedExpensesCompanion.insert(
        id: expense.id,
        name: expense.name,
        amount: expense.amount.value,
        categoryId: expense.category.id,
        accountId: expense.accountId,
        dueDate: CalendarDate.format(expense.dueDate),
        note: Value(expense.note),
        createdAt: _ms(expense.createdAt),
        updatedAt: _nowMs(),
      ),
    );
    return const Ok(null);
  });

  /// Marque la dépense payée le [paidOn] (aujourd'hui au plus tard) : elle
  /// devient une opération datée de ce jour, qui garde la date prévue, et
  /// quitte les dépenses planifiées. Jamais comptée deux fois.
  Future<Result<Transaction>> pay(String id, DateTime paidOn) => _guard(
    () => _db.transaction(() async {
      final expense = await get(id);
      if (expense == null) return const Err(NotFoundFailure());
      final now = _clock();
      if (CalendarDate.of(paidOn).isAfter(CalendarDate.of(now))) {
        return const Err(NotAllowedFailure());
      }
      // Payée aujourd'hui : l'heure actuelle ; un autre jour : midi.
      final occurredAt = CalendarDate.of(paidOn) == CalendarDate.of(now)
          ? now
          : DateTime(paidOn.year, paidOn.month, paidOn.day, 12);
      final result = await _transactions.create(
        TransactionDraft(
          kind: TransactionKind.expense,
          amount: expense.amount,
          occurredAt: occurredAt,
          accountId: expense.accountId,
          categoryId: expense.category.id,
          description: expense.name,
        ),
        planned: PlannedOrigin(
          dueDate: expense.dueDate,
          createdAt: expense.createdAt,
          note: expense.note,
        ),
      );
      if (result is Ok) {
        await (_db.delete(_table)..where((p) => p.id.equals(id))).go();
      }
      return result;
    }),
  );

  Future<Set<PlannedFieldError>> _validate(
    PlannedDraft draft, {
    DateTime? keptDue,
  }) async {
    final errors = draft.validate(_clock(), keptDue: keptDue);
    final accountId = draft.accountId;
    if (accountId != null) {
      final account =
          await (_db.select(_db.accounts)
                ..where((a) => a.id.equals(accountId) & a.archivedAt.isNull()))
              .getSingleOrNull();
      if (account == null) errors.add(PlannedFieldError.accountUnavailable);
    }
    final categoryId = draft.categoryId;
    if (categoryId != null) {
      final category = await (_db.select(
        _db.categories,
      )..where((c) => c.id.equals(categoryId))).getSingleOrNull();
      if (category == null || category.kind != 'expense') {
        errors.add(PlannedFieldError.categoryInvalid);
      }
    }
    return errors;
  }

  PlannedExpensesCompanion _companion(PlannedDraft draft) =>
      PlannedExpensesCompanion(
        name: Value(draft.normalizedName),
        amount: Value(draft.amount.value),
        categoryId: Value(draft.categoryId!),
        accountId: Value(draft.accountId!),
        dueDate: Value(CalendarDate.format(draft.dueDate)),
        note: Value(draft.normalizedNote),
      );

  JoinedSelectStatement<HasResultSet, dynamic> _query() =>
      _db.select(_table).join([
        innerJoin(_db.accounts, _db.accounts.id.equalsExp(_table.accountId)),
        innerJoin(
          _db.categories,
          _db.categories.id.equalsExp(_table.categoryId),
        ),
        leftOuterJoin(_parents, _parents.id.equalsExp(_db.categories.parentId)),
      ])..orderBy([
        OrderingTerm.asc(_table.dueDate),
        OrderingTerm.asc(_table.createdAt),
      ]);

  PlannedExpense _toExpense(TypedResult row) {
    final p = row.readTable(_table);
    final parent = row.readTableOrNull(_parents);
    return PlannedExpense(
      id: p.id,
      name: p.name,
      amount: Money(p.amount),
      category: CategoriesRepository.toCategory(row.readTable(_db.categories)),
      parentCategory: parent == null
          ? null
          : CategoriesRepository.toCategory(parent),
      accountId: p.accountId,
      accountName: row.readTable(_db.accounts).name,
      dueDate: CalendarDate.parse(p.dueDate),
      createdAt: DateTime.fromMillisecondsSinceEpoch(p.createdAt, isUtc: true),
      note: p.note,
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
