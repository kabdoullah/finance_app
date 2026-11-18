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
import '../domain/recurrence.dart';
import '../domain/recurring_draft.dart';
import '../domain/recurring_operation.dart';

/// Modèles d'opérations récurrentes et traitement de leurs échéances.
class RecurringRepository {
  RecurringRepository(
    this._db,
    this._clock,
    this._transactions, {
    String Function()? newId,
  }) : _newId = newId ?? const Uuid().v4;

  final AppDatabase _db;
  final Clock _clock;
  final TransactionsRepository _transactions;
  final String Function() _newId;

  $RecurringOperationsTable get _table => _db.recurringOperations;
  late final _parents = _db.alias(_db.categories, 'parent');

  /// Heure d'enregistrement d'une échéance (le jour prévu).
  static const recordHour = 8;

  /// Modèles actifs d'abord (par prochaine échéance), puis en pause.
  Stream<List<RecurringOperation>> watchAll() => _query().watch().map(
    (rows) => rows.map(_toOperation).toList()
      ..sort((a, b) {
        if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
        final da = a.nextDue, db = b.nextDue;
        if (da == null || db == null) return a.name.compareTo(b.name);
        return da.compareTo(db);
      }),
  );

  Future<RecurringOperation?> get(String id) async {
    final row = await (_query()..where(_table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toOperation(row);
  }

  Future<Result<RecurringOperation>> create(RecurringDraft draft) =>
      _guard(() async {
        final errors = await _validate(draft);
        if (errors.isNotEmpty) return Err(ValidationFailure(errors));
        final id = _newId();
        final now = _nowMs();
        final recurrence = draft.recurrence;
        await _table.insertOne(
          _companion(draft).copyWith(
            id: Value(id),
            nextDueDate: Value(
              _format(recurrence.firstOnOrAfter(recurrence.start)),
            ),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        return Ok((await get(id))!);
      });

  /// Les modifications ne valent que pour les échéances à venir : celles
  /// déjà en attente restent dues, les opérations passées ne changent pas.
  Future<Result<RecurringOperation>> update(String id, RecurringDraft draft) =>
      _guard(() async {
        final current = await get(id);
        if (current == null) return const Err(NotFoundFailure());
        final errors = await _validate(draft);
        if (errors.isNotEmpty) return Err(ValidationFailure(errors));
        final recurrence = draft.recurrence;
        final from = current.nextDue ?? CalendarDate.of(_clock());
        await (_db.update(_table)..where((r) => r.id.equals(id))).write(
          _companion(draft).copyWith(
            nextDueDate: Value(
              _format(
                recurrence.firstOnOrAfter(
                  from.isAfter(recurrence.start) ? from : recurrence.start,
                ),
              ),
            ),
            updatedAt: Value(_nowMs()),
          ),
        );
        return Ok((await get(id))!);
      });

  /// Supprime le modèle ; ses opérations déjà enregistrées restent
  /// (détachées par la clé étrangère `ON DELETE SET NULL`).
  Future<Result<void>> delete(String id) => _guard(() async {
    final count = await (_db.delete(
      _table,
    )..where((r) => r.id.equals(id))).go();
    return count == 0 ? const Err(NotFoundFailure()) : const Ok(null);
  });

  /// Pause : plus d'échéance. Reprise : prochaine échéance à partir
  /// d'aujourd'hui (les échéances de la pause sont ignorées).
  Future<Result<RecurringOperation>> setPaused(
    String id, {
    required bool paused,
  }) => _guard(() async {
    final current = await get(id);
    if (current == null) return const Err(NotFoundFailure());
    final recurrence = current.recurrence;
    final today = CalendarDate.of(_clock());
    await (_db.update(_table)..where((r) => r.id.equals(id))).write(
      RecurringOperationsCompanion(
        pausedAt: Value(paused ? _nowMs() : null),
        nextDueDate: paused
            ? const Value.absent()
            : Value(
                _format(
                  recurrence.firstOnOrAfter(
                    today.isAfter(recurrence.start) ? today : recurrence.start,
                  ),
                ),
              ),
        updatedAt: Value(_nowMs()),
      ),
    );
    return Ok((await get(id))!);
  });

  /// Enregistre l'échéance [due] (la plus ancienne non traitée) comme
  /// opération, avec [amount] si le montant est variable.
  Future<Result<Transaction>> record(
    String id,
    DateTime due, {
    Money? amount,
  }) => _guard(
    () => _db.transaction(() async {
      final operation = await get(id);
      if (operation == null) return const Err(NotFoundFailure());
      if (operation.nextDue != CalendarDate.of(due)) {
        return const Err(NotAllowedFailure());
      }
      final result = await _transactions.create(
        TransactionDraft(
          kind: operation.kind,
          amount: amount ?? operation.amount,
          occurredAt: DateTime(due.year, due.month, due.day, recordHour),
          accountId: operation.accountId,
          categoryId: operation.category.id,
          description: operation.name,
        ),
        entryMethod: EntryMethod.recurring,
        recurringId: id,
      );
      if (result is Ok) await _advance(operation, due);
      return result;
    }),
  );

  /// « Pas ce mois-ci » : passe l'échéance sans rien enregistrer.
  Future<Result<void>> skip(String id, DateTime due) => _guard(() async {
    final operation = await get(id);
    if (operation == null) return const Err(NotFoundFailure());
    if (operation.nextDue != CalendarDate.of(due)) {
      return const Err(NotAllowedFailure());
    }
    await _advance(operation, due);
    return const Ok(null);
  });

  /// Enregistre, à leur date, toutes les échéances passées ou du jour des
  /// modèles actifs qui ne demandent pas de confirmation. Retourne le nombre
  /// d'opérations créées. Une échéance impossible à enregistrer (compte
  /// archivé…) reste en attente.
  Future<int> recordAutomatic() async {
    final today = CalendarDate.of(_clock());
    final operations = (await _query().get()).map(_toOperation);
    var recorded = 0;
    for (final operation in operations) {
      if (operation.askBeforeRecording) continue;
      for (final due in operation.dueUntil(today)) {
        if (await record(operation.id, due) is! Ok) break;
        recorded++;
      }
    }
    return recorded;
  }

  Future<void> _advance(RecurringOperation operation, DateTime due) =>
      (_db.update(_table)..where((r) => r.id.equals(operation.id))).write(
        RecurringOperationsCompanion(
          nextDueDate: Value(_format(operation.recurrence.after(due))),
          updatedAt: Value(_nowMs()),
        ),
      );

  Future<Set<RecurringFieldError>> _validate(RecurringDraft draft) async {
    final errors = draft.validate();
    final accountId = draft.accountId;
    if (accountId != null) {
      final account =
          await (_db.select(_db.accounts)
                ..where((a) => a.id.equals(accountId) & a.archivedAt.isNull()))
              .getSingleOrNull();
      if (account == null) errors.add(RecurringFieldError.accountUnavailable);
    }
    final categoryId = draft.categoryId;
    final categoryKind = draft.kind.categoryKind;
    if (categoryId != null) {
      final category = await (_db.select(
        _db.categories,
      )..where((c) => c.id.equals(categoryId))).getSingleOrNull();
      if (category == null ||
          categoryKind == null ||
          category.kind != categoryKind.storageValue) {
        errors.add(RecurringFieldError.categoryInvalid);
      }
    }
    return errors;
  }

  RecurringOperationsCompanion _companion(RecurringDraft draft) =>
      RecurringOperationsCompanion(
        kind: Value(draft.kind.storageValue),
        name: Value(draft.normalizedName),
        amount: Value(draft.amount.value),
        isVariable: Value(draft.isVariable),
        categoryId: Value(draft.categoryId!),
        accountId: Value(draft.accountId!),
        frequency: Value(draft.frequency.storageValue),
        startDate: Value(CalendarDate.format(draft.startDate)),
        endDate: Value(
          draft.endDate == null ? null : CalendarDate.format(draft.endDate!),
        ),
        askBeforeRecording: Value(draft.askBeforeRecording),
      );

  JoinedSelectStatement<HasResultSet, dynamic> _query() =>
      _db.select(_table).join([
        innerJoin(_db.accounts, _db.accounts.id.equalsExp(_table.accountId)),
        innerJoin(
          _db.categories,
          _db.categories.id.equalsExp(_table.categoryId),
        ),
        leftOuterJoin(_parents, _parents.id.equalsExp(_db.categories.parentId)),
      ]);

  RecurringOperation _toOperation(TypedResult row) {
    final r = row.readTable(_table);
    final parent = row.readTableOrNull(_parents);
    final end = r.endDate;
    final next = r.nextDueDate;
    return RecurringOperation(
      id: r.id,
      kind: TransactionKind.fromStorage(r.kind),
      name: r.name,
      amount: Money(r.amount),
      isVariable: r.isVariable,
      category: CategoriesRepository.toCategory(row.readTable(_db.categories)),
      parentCategory: parent == null
          ? null
          : CategoriesRepository.toCategory(parent),
      accountId: r.accountId,
      accountName: row.readTable(_db.accounts).name,
      recurrence: Recurrence(
        frequency: RecurrenceFrequency.fromStorage(r.frequency),
        start: CalendarDate.parse(r.startDate),
        end: end == null ? null : CalendarDate.parse(end),
      ),
      nextDue: next == null ? null : CalendarDate.parse(next),
      askBeforeRecording: r.askBeforeRecording,
      isPaused: r.pausedAt != null,
    );
  }

  static String? _format(DateTime? date) =>
      date == null ? null : CalendarDate.format(date);

  int _nowMs() => _clock().toUtc().millisecondsSinceEpoch;

  /// Convertit les erreurs SQLite inattendues en [StorageFailure].
  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      return Err(StorageFailure(error, stackTrace));
    }
  }
}
