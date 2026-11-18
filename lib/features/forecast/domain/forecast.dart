import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../recurring/domain/recurring_operation.dart';
import '../../transactions/domain/transaction.dart';

/// Horizons proposés par l'écran Prévisions.
enum ForecastHorizon {
  week(7),
  month(30),
  quarter(90);

  const ForecastHorizon(this.days);

  final int days;
}

enum ForecastReliability { low, medium, high }

/// Historique utile au calcul, agrégé par jour calendaire local.
@immutable
class SpendingHistory {
  const SpendingHistory({
    required this.firstDay,
    required this.variableExpenseByDay,
    required this.netByDay,
  });

  static const empty = SpendingHistory(
    firstDay: null,
    variableExpenseByDay: {},
    netByDay: {},
  );

  /// Jour de la première opération ; `null` s'il n'y en a aucune.
  final DateTime? firstDay;

  /// Dépenses hors opérations récurrentes, par jour (90 derniers jours).
  final Map<DateTime, int> variableExpenseByDay;

  /// Revenus − dépenses par jour (transferts exclus, 14 derniers jours).
  final Map<DateTime, int> netByDay;

  /// Nombre de jours d'historique, aujourd'hui compris.
  int daysOfHistory(DateTime today) {
    final first = firstDay;
    if (first == null) return 0;
    return _daysBetween(first, CalendarDate.of(today)) + 1;
  }
}

/// Opération attendue dans la période (« Ce qui est attendu »).
@immutable
class ForecastEvent {
  const ForecastEvent({
    required this.date,
    required this.name,
    required this.amount,
    required this.isEstimate,
  });

  final DateTime date;
  final String name;

  /// Montant signé (revenu +, dépense −).
  final Money amount;

  /// Montant variable : c'est une estimation.
  final bool isEstimate;
}

/// Point bas prévu (« solde bas possible »).
@immutable
class LowBalanceRisk {
  const LowBalanceRisk({
    required this.date,
    required this.balance,
    required this.beforeIncome,
  });

  final DateTime date;
  final Money balance;

  /// Un revenu récurrent arrive le lendemain (« juste avant ton salaire »).
  final bool beforeIncome;
}

/// Prévision du solde total (moteur déterministe, sans IA).
@immutable
class Forecast {
  const Forecast._({
    required this.horizon,
    required this.today,
    required this.balance,
    required this.dailyVariable,
    required this.spread,
    required this.points,
    required this.history,
    required this.events,
    required this.reliability,
    required this.negativeOn,
    required this.lowBalance,
  });

  /// Jours d'historique nécessaires avant de prévoir.
  static const minHistoryDays = 14;

  /// Fenêtre des dépenses variables.
  static const variableWindowDays = 90;

  /// En dessous de N jours de dépenses variables, le solde est « bas ».
  static const lowBalanceDays = 7;

  factory Forecast.compute({
    required DateTime now,
    required ForecastHorizon horizon,
    required Money balance,
    required SpendingHistory history,
    required List<RecurringOperation> recurring,
  }) {
    final today = CalendarDate.of(now);
    final days = horizon.days;
    final end = DateTime(today.year, today.month, today.day + days);

    // Dépenses variables : moyenne et écart type par jour sur la fenêtre.
    final windowDays = math.min(
      variableWindowDays,
      math.max(1, history.daysOfHistory(today)),
    );
    final daily = [
      for (var k = 0; k < windowDays; k++)
        history.variableExpenseByDay[DateTime(
              today.year,
              today.month,
              today.day - k,
            )] ??
            0,
    ];
    final mean = daily.fold<int>(0, (a, b) => a + b) / windowDays;
    final variance =
        daily.fold<double>(0, (a, b) => a + (b - mean) * (b - mean)) /
        windowDays;
    final sd = math.sqrt(variance);

    // Opérations récurrentes : les échéances en retard comptent aujourd'hui.
    final events = <ForecastEvent>[
      for (final op in recurring)
        if (!op.isPaused)
          for (final due in op.recurrence.dueBetween(op.nextDue, end, max: 400))
            ForecastEvent(
              date: due.isBefore(today) ? today : due,
              name: op.name,
              amount: op.kind == TransactionKind.income
                  ? op.amount
                  : Money(-op.amount.value),
              isEstimate: op.isVariable,
            ),
    ]..sort((a, b) => a.date.compareTo(b.date));

    // Solde prévu jour par jour (d = 0 : solde actuel).
    final points = <Money>[balance];
    var running = balance.value.toDouble();
    var eventIndex = 0;
    for (var d = 1; d <= days; d++) {
      final day = DateTime(today.year, today.month, today.day + d);
      running -= mean;
      while (eventIndex < events.length &&
          !events[eventIndex].date.isAfter(day)) {
        running += events[eventIndex].amount.value;
        eventIndex++;
      }
      points.add(Money(running.round()));
    }

    // Passé : solde en fin de journée, en remontant depuis aujourd'hui.
    final back = horizon == ForecastHorizon.week ? 7 : 14;
    final past = <Money>[];
    var value = balance.value;
    for (var k = 0; k <= back; k++) {
      past.insert(0, Money(value));
      value -=
          history.netByDay[DateTime(today.year, today.month, today.day - k)] ??
          0;
    }

    final negativeIndex = points.indexWhere((p) => p.value < 0);

    // Point bas : minimum de la période sous 7 jours de dépenses variables.
    LowBalanceRisk? low;
    if (negativeIndex < 0 && points.length > 1) {
      var minIndex = 1;
      for (var d = 2; d < points.length; d++) {
        if (points[d].value < points[minIndex].value) minIndex = d;
      }
      final threshold = mean * lowBalanceDays;
      if (mean > 0 && points[minIndex].value < threshold) {
        final date = DateTime(today.year, today.month, today.day + minIndex);
        final next = DateTime(date.year, date.month, date.day + 1);
        low = LowBalanceRisk(
          date: date,
          balance: points[minIndex],
          beforeIncome: events.any((e) => e.date == next && e.amount.value > 0),
        );
      }
    }

    var reliability = switch (horizon) {
      ForecastHorizon.week => ForecastReliability.high,
      ForecastHorizon.month => ForecastReliability.medium,
      ForecastHorizon.quarter => ForecastReliability.low,
    };
    if (history.daysOfHistory(today) < 30 &&
        reliability != ForecastReliability.low) {
      reliability = ForecastReliability.values[reliability.index - 1];
    }

    return Forecast._(
      horizon: horizon,
      today: today,
      balance: balance,
      dailyVariable: Money(mean.round()),
      spread: sd,
      points: points,
      history: past,
      events: events,
      reliability: reliability,
      negativeOn: negativeIndex < 0
          ? null
          : DateTime(today.year, today.month, today.day + negativeIndex),
      lowBalance: low,
    );
  }

  final ForecastHorizon horizon;
  final DateTime today;

  /// Solde total actuel.
  final Money balance;

  /// Dépenses variables moyennes par jour.
  final Money dailyVariable;

  /// Écart type des dépenses variables par jour.
  final double spread;

  /// Solde prévu, du jour 0 (aujourd'hui) au dernier jour de l'horizon.
  final List<Money> points;

  /// Solde en fin de journée sur les 7 ou 14 derniers jours (dernier =
  /// aujourd'hui).
  final List<Money> history;

  final List<ForecastEvent> events;
  final ForecastReliability reliability;

  /// Premier jour où le solde prévu passe sous zéro.
  final DateTime? negativeOn;
  final LowBalanceRisk? lowBalance;

  DateTime get endDate =>
      DateTime(today.year, today.month, today.day + horizon.days);

  /// Solde prévu en fin d'horizon, arrondi au millier.
  Money get endBalance => _round(points.last.value, 1000);

  /// Demi-largeur de la fourchette au jour [d] : écart type × √d.
  double bandAt(int d) => spread * math.sqrt(d);

  /// Fourchette probable en fin d'horizon, arrondie aux 5 000.
  (Money, Money) get endRange {
    final width = bandAt(horizon.days);
    return (
      _round((points.last.value - width).round(), 5000),
      _round((points.last.value + width).round(), 5000),
    );
  }

  Money get expectedIncome => Money(
    events
        .where((e) => e.amount.value > 0)
        .fold(0, (sum, e) => sum + e.amount.value),
  );

  /// Dépenses récurrentes + dépenses variables sur la période.
  Money get expectedExpenses => Money(
    events
            .where((e) => e.amount.value < 0)
            .fold(0, (sum, e) => sum - e.amount.value) +
        dailyVariable.value * horizon.days,
  );

  static Money _round(int value, int step) =>
      Money((value / step).round() * step);
}

int _daysBetween(DateTime from, DateTime to) =>
    (to.difference(from).inHours / 24).round();
