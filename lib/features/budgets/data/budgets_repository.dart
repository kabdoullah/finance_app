import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/result.dart';
import '../../../core/money/money.dart';
import '../../../core/time/month.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/domain/category.dart';
import '../domain/budget.dart';
import '../domain/budget_draft.dart';

/// Budgets mensuels (global et par catégorie principale de dépenses).
class BudgetsRepository {
  BudgetsRepository(
    this._db,
    this._clock, {
    this.monthStartDay = 1,
    String Function()? newId,
  }) : _newId = newId ?? const Uuid().v4;

  final AppDatabase _db;
  final Clock _clock;

  /// Début du mois budgétaire.
  final int monthStartDay;
  final String Function() _newId;

  $BudgetsTable get _budgets => _db.budgets;

  /// Tous les budgets : le global d'abord, puis par ordre de création.
  Stream<List<Budget>> watchAll() {
    final query =
        _db.select(_budgets).join([
          leftOuterJoin(
            _db.categories,
            _db.categories.id.equalsExp(_budgets.categoryId),
          ),
        ])..orderBy([
          OrderingTerm.asc(_budgets.categoryId.isNotNull()),
          OrderingTerm.asc(_budgets.createdAt),
        ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          _toBudget(
            row.readTable(_budgets),
            row.readTableOrNull(_db.categories),
          ),
      ],
    );
  }

  Future<Result<Budget>> create(BudgetDraft draft) => _guard(() async {
    final errors = draft.validate();
    final categoryId = draft.categoryId;
    if (categoryId != null) {
      final category = await (_db.select(
        _db.categories,
      )..where((c) => c.id.equals(categoryId))).getSingleOrNull();
      if (category == null ||
          category.parentId != null ||
          category.kind != CategoryKind.expense.storageValue) {
        errors.add(BudgetFieldError.categoryInvalid);
      }
    }
    if (await _exists(categoryId)) errors.add(BudgetFieldError.alreadyExists);
    if (errors.isNotEmpty) return Err(ValidationFailure(errors));

    final id = _newId();
    final now = _nowMs();
    await _budgets.insertOne(
      BudgetsCompanion.insert(
        id: id,
        categoryId: Value(categoryId),
        limitAmount: draft.limit.value,
        alertPercent: draft.alertPercent,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return Ok((await _get(id))!);
  });

  /// Modifie la limite et le seuil (la catégorie d'un budget ne change pas).
  Future<Result<Budget>> update(String id, BudgetDraft draft) =>
      _guard(() async {
        final errors = draft.validate();
        if (errors.isNotEmpty) return Err(ValidationFailure(errors));
        final count =
            await (_db.update(_budgets)..where((b) => b.id.equals(id))).write(
              BudgetsCompanion(
                limitAmount: Value(draft.limit.value),
                alertPercent: Value(draft.alertPercent),
                updatedAt: Value(_nowMs()),
              ),
            );
        if (count == 0) return const Err(NotFoundFailure());
        return Ok((await _get(id))!);
      });

  Future<Result<void>> delete(String id) => _guard(() async {
    final count = await (_db.delete(
      _budgets,
    )..where((b) => b.id.equals(id))).go();
    return count == 0 ? const Err(NotFoundFailure()) : const Ok(null);
  });

  /// Moyenne mensuelle des dépenses des 3 derniers mois complets (suggestion
  /// « Ces 3 derniers mois, tu as dépensé en moyenne… »), arrondie à la
  /// centaine. [categoryId] `null` = toutes les dépenses.
  Future<Money> averageMonthlySpending(String? categoryId) async {
    final current = Month.of(_clock(), startDay: monthStartDay);
    final from = current.previous.previous.previous.start;
    final t = _db.transactions;
    final total = t.amount.sum();
    final query = _db.selectOnly(t)
      ..addColumns([total])
      ..where(
        t.kind.equals('expense') &
            t.occurredAt.isBetweenValues(_ms(from), _ms(current.start) - 1),
      );
    if (categoryId != null) {
      final children = await (_db.select(
        _db.categories,
      )..where((c) => c.parentId.equals(categoryId))).get();
      query.where(
        t.categoryId.isIn([categoryId, for (final c in children) c.id]),
      );
    }
    final sum = (await query.getSingle()).read(total) ?? 0;
    final average = sum ~/ 3;
    return Money(average - average % 100);
  }

  Future<bool> _exists(String? categoryId) async {
    final query = _db.selectOnly(_budgets)
      ..addColumns([_budgets.id])
      ..where(
        categoryId == null
            ? _budgets.categoryId.isNull()
            : _budgets.categoryId.equals(categoryId),
      )
      ..limit(1);
    return (await query.getSingleOrNull()) != null;
  }

  Future<Budget?> _get(String id) async {
    final row = await (_db.select(
      _budgets,
    )..where((b) => b.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final categoryId = row.categoryId;
    final category = categoryId == null
        ? null
        : await (_db.select(
            _db.categories,
          )..where((c) => c.id.equals(categoryId))).getSingleOrNull();
    return _toBudget(row, category);
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

  static Budget _toBudget(BudgetRow row, CategoryRow? category) => Budget(
    id: row.id,
    category: category == null
        ? null
        : CategoriesRepository.toCategory(category),
    limit: Money(row.limitAmount),
    alertPercent: row.alertPercent,
  );
}
