import 'package:flutter/foundation.dart' show immutable;

import '../../../core/formatting/date_format.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../l10n/l10n.dart';
import '../../budgets/domain/budget.dart';
import '../../forecast/domain/forecast.dart';
import '../../recurring/domain/recurring_operation.dart';
import '../../transactions/domain/transaction.dart';

/// Famille de notification (une chaîne Android et un interrupteur chacune).
enum NoticeKind { reminder, budget, lowBalance }

/// Notification calculée par l'application, à afficher à [at] (heure
/// locale). [route] : écran ouvert au toucher.
@immutable
class PlannedNotice {
  const PlannedNotice({
    required this.id,
    required this.kind,
    required this.at,
    required this.title,
    required this.body,
    required this.route,
  });

  final int id;
  final NoticeKind kind;
  final DateTime at;
  final String title;
  final String body;
  final String route;
}

/// Calcul déterministe des notifications : rappels d'échéance, solde bas
/// et franchissements de seuil des budgets.
abstract final class NotificationPlan {
  /// Heure des rappels.
  static const hour = 9;

  /// Rappels programmés à l'avance (reprogrammés à chaque ouverture).
  static const horizonDays = 30;

  /// Solde bas : prévenir ce nombre de jours avant.
  static const lowBalanceLeadDays = 3;

  /// Identifiants : rappels à partir de 1000, solde bas 900, budgets 2000+.
  static const _reminderBaseId = 1000;
  static const lowBalanceId = 900;
  static const _budgetBaseId = 2000;

  static const _locale = 'fr';

  /// Rappels d'échéance des modèles actifs sur les [horizonDays] prochains
  /// jours, à 9 h ; ceux déjà passés ne sont pas programmés.
  static List<PlannedNotice> reminders({
    required Iterable<RecurringOperation> operations,
    required DateTime now,
    required AppLocalizations l10n,
    required String route,
  }) {
    final today = CalendarDate.of(now);
    final until = DateTime(today.year, today.month, today.day + horizonDays);
    final dated = <(DateTime, RecurringOperation)>[];
    for (final operation in operations.where((o) => o.isActive)) {
      for (final due in operation.recurrence.dueBetween(
        operation.nextDue,
        until,
        max: 40,
      )) {
        final at = DateTime(due.year, due.month, due.day, hour);
        if (at.isAfter(now)) dated.add((at, operation));
      }
    }
    dated.sort((a, b) => a.$1.compareTo(b.$1));
    return [
      for (final (i, (at, operation)) in dated.indexed)
        PlannedNotice(
          id: _reminderBaseId + i,
          kind: NoticeKind.reminder,
          at: at,
          title: l10n.ntReminderTitle(
            operation.name,
            operation.kind == TransactionKind.income
                ? MoneyFormat.signed(operation.amount)
                : MoneyFormat.amount(operation.amount),
          ),
          body: operation.askBeforeRecording
              ? l10n.ntReminderConfirm
              : l10n.ntReminderAuto,
          route: route,
        ),
    ];
  }

  /// « Solde bas possible le … », 3 jours avant, à 9 h ; rien si la
  /// prévision ne l'annonce pas ou si ce moment est passé.
  static PlannedNotice? lowBalance({
    required Forecast? forecast,
    required DateTime now,
    required AppLocalizations l10n,
    required String route,
  }) {
    final risk = forecast?.lowBalance;
    if (risk == null) return null;
    final at = DateTime(
      risk.date.year,
      risk.date.month,
      risk.date.day - lowBalanceLeadDays,
      hour,
    );
    if (!at.isAfter(now)) return null;
    return PlannedNotice(
      id: lowBalanceId,
      kind: NoticeKind.lowBalance,
      at: at,
      title: AppDateFormat.sentence(
        l10n.ntLowBalanceTitle(AppDateFormat.dayMonth(risk.date, _locale)),
      ),
      body: l10n.ntLowBalanceBody(MoneyFormat.amount(risk.balance)),
      route: route,
    );
  }

  /// Niveau d'alerte retenu pour les notifications : 0 rien, 1 seuil
  /// d'alerte, 2 budget atteint ou dépassé.
  static int alertLevel(BudgetStatus status) => switch (status.level) {
    BudgetLevel.ok => 0,
    BudgetLevel.warning => 1,
    BudgetLevel.reached || BudgetLevel.exceeded => 2,
  };

  /// Budgets qui viennent de franchir un niveau : [notified] donne le
  /// niveau déjà signalé ce mois-ci pour chaque budget (absent = 0).
  static List<(BudgetStatus, PlannedNotice)> budgetCrossings({
    required BudgetsOverview overview,
    required Map<String, int> notified,
    required DateTime now,
    required AppLocalizations l10n,
    required String route,
  }) => [
    for (final status in [?overview.global, ...overview.categories])
      if (alertLevel(status) > (notified[status.budget.id] ?? 0))
        (status, _budgetNotice(status, now, l10n, route)),
  ];

  static PlannedNotice _budgetNotice(
    BudgetStatus status,
    DateTime now,
    AppLocalizations l10n,
    String route,
  ) {
    final name = status.budget.category?.name ?? l10n.budgetAllExpenses;
    final (title, body) = switch (status.level) {
      BudgetLevel.exceeded => (
        l10n.ntBudgetExceededTitle(name, MoneyFormat.amount(-status.remaining)),
        l10n.ntBudgetBody,
      ),
      BudgetLevel.reached => (
        l10n.ntBudgetReachedTitle(name),
        l10n.ntBudgetBody,
      ),
      _ => (
        l10n.ntBudgetWarningTitle(name, '${status.percent}'),
        l10n.ntBudgetWarningBody(MoneyFormat.amount(status.remaining)),
      ),
    };
    return PlannedNotice(
      id: _budgetBaseId + status.budget.id.hashCode.abs() % 1000,
      kind: NoticeKind.budget,
      at: now,
      title: title,
      body: body,
      route: route,
    );
  }

  /// Clé du mois pour mémoriser les alertes déjà envoyées (« 2026-11 »).
  static String monthKey(DateTime now) =>
      '${now.year}-${now.month.toString().padLeft(2, '0')}';
}
