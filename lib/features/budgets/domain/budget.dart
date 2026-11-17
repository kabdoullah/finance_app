import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction.dart';

/// Budget mensuel : global (`category == null`) ou par catégorie principale.
@immutable
class Budget {
  const Budget({
    required this.id,
    required this.limit,
    required this.alertPercent,
    this.category,
  });

  final String id;
  final Category? category;

  /// Limite mensuelle en FCFA.
  final Money limit;

  /// Seuil d'avertissement (« M'avertir quand j'atteins »), 50 à 100 %.
  final int alertPercent;

  bool get isGlobal => category == null;
}

/// Niveau d'un budget : ambre au seuil choisi, « Payé » à 100 % pile,
/// brique au-delà.
enum BudgetLevel { ok, warning, reached, exceeded }

/// État d'un budget pour le mois en cours. Calcul déterministe.
@immutable
class BudgetStatus {
  const BudgetStatus._(this.budget, this.spent);

  factory BudgetStatus.of(Budget budget, Money spent) =>
      BudgetStatus._(budget, spent);

  final Budget budget;

  /// Dépenses du mois imputées au budget.
  final Money spent;

  /// Reste (négatif en cas de dépassement).
  Money get remaining => budget.limit - spent;

  /// Pourcentage consommé (peut dépasser 100).
  int get percent => spent.value * 100 ~/ budget.limit.value;

  BudgetLevel get level {
    if (spent.value > budget.limit.value) return BudgetLevel.exceeded;
    if (spent.value == budget.limit.value) return BudgetLevel.reached;
    if (spent.value * 100 >= budget.limit.value * budget.alertPercent) {
      return BudgetLevel.warning;
    }
    return BudgetLevel.ok;
  }
}

/// Dépenses d'un mois par catégorie principale, et total.
@immutable
class MonthSpending {
  const MonthSpending._(this.total, this.byMainCategory);

  factory MonthSpending.of(Iterable<Transaction> transactions) {
    var total = Money.zero;
    final byCategory = <String, Money>{};
    for (final t in transactions) {
      final category = t.mainCategory;
      if (t.kind != TransactionKind.expense || category == null) continue;
      total += t.amount;
      byCategory[category.id] =
          (byCategory[category.id] ?? Money.zero) + t.amount;
    }
    return MonthSpending._(total, byCategory);
  }

  final Money total;
  final Map<String, Money> byMainCategory;

  Money spentFor(Budget budget) => budget.isGlobal
      ? total
      : byMainCategory[budget.category!.id] ?? Money.zero;
}

/// Vue de l'onglet Budgets pour un mois.
@immutable
class BudgetsOverview {
  const BudgetsOverview._({
    required this.global,
    required this.categories,
    required this.withoutBudget,
  });

  /// [expenseCategories] : catégories principales de dépenses (non masquées).
  factory BudgetsOverview.of({
    required List<Budget> budgets,
    required Iterable<Transaction> monthTransactions,
    required List<Category> expenseCategories,
  }) {
    final spending = MonthSpending.of(monthTransactions);
    BudgetStatus status(Budget b) => BudgetStatus.of(b, spending.spentFor(b));
    final global = budgets.where((b) => b.isGlobal).firstOrNull;
    final byCategory = [
      for (final b in budgets)
        if (!b.isGlobal) status(b),
    ];
    final budgeted = {for (final s in byCategory) s.budget.category!.id};
    return BudgetsOverview._(
      global: global == null ? null : status(global),
      categories: byCategory,
      withoutBudget: [
        for (final c in expenseCategories)
          if (!budgeted.contains(c.id)) c,
      ],
    );
  }

  final BudgetStatus? global;
  final List<BudgetStatus> categories;
  final List<Category> withoutBudget;

  /// Budgets dépassés (alertes de l'onglet).
  List<BudgetStatus> get exceeded => [
    for (final s in [?global, ...categories])
      if (s.level == BudgetLevel.exceeded) s,
  ];
}

/// Somme disponible par jour jusqu'à la fin du mois (jour courant inclus),
/// arrondie à la centaine inférieure ; 0 si le budget est épuisé.
Money dailyAllowance(Money remaining, int daysLeft) {
  if (remaining.value <= 0 || daysLeft <= 0) return Money.zero;
  final perDay = remaining.value ~/ daysLeft;
  return Money(perDay - perDay % 100);
}
