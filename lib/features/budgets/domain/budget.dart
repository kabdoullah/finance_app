import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../../../core/time/month.dart';
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
    required this.forecasts,
    required this.monthTransactions,
    required this.month,
  });

  /// [expenseCategories] : catégories principales de dépenses (non masquées).
  factory BudgetsOverview.of({
    required List<Budget> budgets,
    required Iterable<Transaction> monthTransactions,
    required List<Category> expenseCategories,
    required DateTime now,
    Month? month,
  }) {
    final period = month ?? Month.of(now);
    final spending = MonthSpending.of(monthTransactions);
    BudgetStatus status(Budget b) => BudgetStatus.of(b, spending.spentFor(b));
    final transactions = List<Transaction>.of(monthTransactions);
    final global = budgets.where((b) => b.isGlobal).firstOrNull;
    final byCategory = [
      for (final b in budgets)
        if (!b.isGlobal) status(b),
    ];
    final budgeted = {for (final s in byCategory) s.budget.category!.id};
    final globalStatus = global == null ? null : status(global);
    final forecasts = [
      for (final s in [?globalStatus, ...byCategory])
        if (projectedOverrun(s, now, period) case final date?) (s, date),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return BudgetsOverview._(
      global: globalStatus,
      categories: byCategory,
      forecasts: forecasts,
      monthTransactions: transactions,
      month: period,
      withoutBudget: [
        for (final c in expenseCategories)
          if (!budgeted.contains(c.id)) c,
      ],
    );
  }

  final BudgetStatus? global;
  final List<BudgetStatus> categories;
  final List<Category> withoutBudget;

  /// Budgets qui seraient dépassés avant la fin du mois, du plus proche au
  /// plus lointain.
  final List<(BudgetStatus, DateTime)> forecasts;

  /// Opérations du mois (pour l'explication des dépassements).
  final List<Transaction> monthTransactions;

  /// Mois budgétaire de la vue.
  final Month month;

  BudgetDriver? driverOf(BudgetStatus status) =>
      BudgetDriver.of(status.budget, monthTransactions);

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

/// Jour du mois budgétaire à partir duquel la prévision est affichée :
/// avant, une seule grosse dépense (loyer en début de mois…) fausserait le
/// rythme.
const forecastFirstDay = 5;

/// Date prévue de dépassement au rythme moyen du mois (dépensé ÷ jours
/// écoulés, aujourd'hui compris). `null` si le budget est déjà dépassé,
/// avant le [forecastFirstDay], sans dépense, ou si le dépassement tomberait
/// après la fin du mois.
DateTime? projectedOverrun(BudgetStatus status, DateTime now, Month month) {
  final spent = status.spent.value;
  final remaining = status.remaining.value;
  final elapsed = month.dayOf(now);
  if (remaining < 0 || spent <= 0 || elapsed < forecastFirstDay) return null;
  // Plus petit k ≥ 1 tel que spent + (spent / jours écoulés) × k > limit.
  final days = remaining * elapsed ~/ spent + 1;
  final date = DateTime(now.year, now.month, now.day + days);
  return month.contains(date) ? date : null;
}

/// Sous-catégorie qui pèse le plus dans un budget (« Surtout à cause
/// de Taxi : 6 opérations, 18 000 FCFA ce mois-ci »).
@immutable
class BudgetDriver {
  const BudgetDriver(this.category, this.count, this.total);

  final Category category;
  final int count;
  final Money total;

  /// `null` si le budget est global, s'il n'y a pas de dépense, ou si les
  /// dépenses rangées directement dans la catégorie principale pèsent plus.
  static BudgetDriver? of(Budget budget, Iterable<Transaction> month) {
    final main = budget.category;
    if (main == null) return null;
    final byCategory = <String, (Category, int, Money)>{};
    for (final t in month) {
      final category = t.category;
      if (t.kind != TransactionKind.expense ||
          category == null ||
          t.mainCategory?.id != main.id) {
        continue;
      }
      final (_, count, total) =
          byCategory[category.id] ?? (category, 0, Money.zero);
      byCategory[category.id] = (category, count + 1, total + t.amount);
    }
    final top = byCategory.values.fold<(Category, int, Money)?>(
      null,
      (best, e) => best == null || e.$3.value > best.$3.value ? e : best,
    );
    if (top == null || top.$1.id == main.id) return null;
    return BudgetDriver(top.$1, top.$2, top.$3);
  }
}
