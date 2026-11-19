import 'package:flutter/foundation.dart' show immutable;

import '../../../core/formatting/date_format.dart';
import '../../../core/money/money.dart';
import '../../../core/time/month.dart';
import '../../../l10n/l10n.dart';
import '../../budgets/domain/budget.dart';
import '../../forecast/domain/forecast.dart';
import '../../recurring/domain/recurring_operation.dart';
import '../../transactions/domain/transaction.dart';

/// Suggestion du Copilote sur l'accueil : phrase factuelle écrite par
/// l'application (pas par Gemma), avec la question à poser au Copilote ou
/// l'écran à ouvrir.
@immutable
class HomeInsight {
  const HomeInsight({required this.text, this.question});

  final String text;

  /// Question pour « Demander au Copilote » ; `null` : voir l'échéance.
  final String? question;
}

/// Choisit la suggestion la plus importante, par ordre de priorité :
/// budget dépassé (et sa cause), budget au seuil d'alerte, solde bas prévu,
/// échéance à confirmer, dépenses nettement au-dessus du mois précédent à
/// la même date. `null` s'il n'y a rien à signaler.
abstract final class HomeInsights {
  /// Hausse minimale (en %) et écart minimal pour la dernière règle.
  static const spendingUpPercent = 20;
  static const spendingUpMin = Money(5000);

  static const _locale = 'fr';

  static HomeInsight? pick({
    required BudgetsOverview? budgets,
    required Forecast? forecast,
    required List<PendingOccurrence> pending,
    required List<Transaction> currentMonth,
    required List<Transaction> previousMonth,
    required Month month,
    required DateTime now,
    required AppLocalizations l10n,
  }) =>
      _exceeded(budgets, l10n) ??
      _warning(budgets, month, now, l10n) ??
      _lowBalance(forecast, l10n) ??
      _pending(pending, l10n) ??
      _spendingUp(currentMonth, previousMonth, month, now, l10n);

  static List<BudgetStatus> _statuses(BudgetsOverview? budgets) => [
    ...?budgets?.categories,
    ?budgets?.global,
  ];

  static HomeInsight? _exceeded(
    BudgetsOverview? budgets,
    AppLocalizations l10n,
  ) {
    final exceeded =
        _statuses(budgets)
            .where((s) => s.level == BudgetLevel.exceeded)
            .toList()
          ..sort((a, b) => a.remaining.value.compareTo(b.remaining.value));
    final status = exceeded.firstOrNull;
    if (status == null) return null;
    final amount = MoneyFormat.amount(-status.remaining);
    final category = status.budget.category;
    if (category == null) {
      return HomeInsight(
        text: l10n.inBudgetExceededGlobal(amount),
        question: l10n.inAskBudgetGlobal,
      );
    }
    final driver = budgets!.driverOf(status);
    return HomeInsight(
      text: driver == null
          ? l10n.inBudgetExceeded(category.name, amount)
          : l10n.inBudgetExceededDriver(
              category.name,
              amount,
              driver.category.name,
              '${driver.count}',
            ),
      question: l10n.inAskBudget(category.name),
    );
  }

  static HomeInsight? _warning(
    BudgetsOverview? budgets,
    Month month,
    DateTime now,
    AppLocalizations l10n,
  ) {
    final warned =
        _statuses(budgets).where((s) => s.level == BudgetLevel.warning).toList()
          ..sort((a, b) => b.percent.compareTo(a.percent));
    final status = warned.firstOrNull;
    if (status == null) return null;
    final percent = '${status.percent}';
    final remaining = MoneyFormat.amount(status.remaining);
    final days = '${month.daysLeft(now)}';
    final category = status.budget.category;
    return HomeInsight(
      text: category == null
          ? l10n.inBudgetWarningGlobal(percent, remaining, days)
          : l10n.inBudgetWarning(category.name, percent, remaining, days),
      question: l10n.inAskSpend,
    );
  }

  static HomeInsight? _lowBalance(Forecast? forecast, AppLocalizations l10n) {
    final risk = forecast?.lowBalance;
    if (risk == null) return null;
    final date = AppDateFormat.dayMonth(risk.date, _locale);
    final amount = MoneyFormat.amount(
      Money((risk.balance.value / 1000).round() * 1000),
    );
    return HomeInsight(
      text: AppDateFormat.sentence(
        risk.beforeIncome
            ? l10n.inLowBalanceBeforeIncome(date, amount)
            : l10n.inLowBalance(date, amount),
      ),
      question: l10n.inAskForecast,
    );
  }

  static HomeInsight? _pending(
    List<PendingOccurrence> pending,
    AppLocalizations l10n,
  ) {
    final first = pending.firstOrNull;
    if (first == null) return null;
    return HomeInsight(
      text: l10n.inPending(
        first.operation.name,
        MoneyFormat.amount(first.operation.amount),
      ),
    );
  }

  /// Dépenses du mois jusqu'à aujourd'hui comparées aux mêmes premiers jours
  /// du mois précédent.
  static HomeInsight? _spendingUp(
    List<Transaction> current,
    List<Transaction> previous,
    Month month,
    DateTime now,
    AppLocalizations l10n,
  ) {
    final elapsed = month.dayOf(now);
    final previousStart = month.previous.start;
    final previousCut = DateTime(
      previousStart.year,
      previousStart.month,
      previousStart.day + elapsed,
    );
    int expenses(Iterable<Transaction> ts) => ts
        .where((t) => t.kind == TransactionKind.expense)
        .fold(0, (sum, t) => sum + t.amount.value);
    final spent = expenses(current.where((t) => !t.occurredAt.isAfter(now)));
    final before = expenses(
      previous.where((t) => t.occurredAt.isBefore(previousCut)),
    );
    if (before <= 0 || spent - before < spendingUpMin.value) return null;
    final percent = ((spent - before) * 100 / before).round();
    if (percent < spendingUpPercent) return null;
    return HomeInsight(
      text: l10n.inSpendingUp(
        '$percent',
        MoneyFormat.amount(Money(spent)),
        MoneyFormat.amount(Money(before)),
      ),
      question: l10n.inAskSpendingUp,
    );
  }
}
