import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../app/theme/motion.dart';
import '../../../core/clock.dart';
import '../../../core/errors/error_reporter.dart';
import '../../../l10n/l10n.dart';
import '../../backup/presentation/backup_controller.dart';
import '../../budgets/domain/budget.dart';
import '../../budgets/presentation/budgets_providers.dart';
import '../../forecast/domain/forecast.dart';
import '../../forecast/presentation/forecast_providers.dart';
import '../../planned/presentation/planned_providers.dart';
import '../../recurring/presentation/recurring_providers.dart';
import '../data/notification_service.dart';
import '../domain/notification_plan.dart';

/// Interrupteurs de la section « Notifications » des Paramètres.
/// Toutes activées par défaut.
@immutable
class NotificationSettings {
  const NotificationSettings([this._disabled = const {}]);

  final Set<NoticeKind> _disabled;

  bool isEnabled(NoticeKind kind) => !_disabled.contains(kind);

  NotificationSettings withKind(NoticeKind kind, bool value) =>
      NotificationSettings(
        value ? (_disabled.toSet()..remove(kind)) : {..._disabled, kind},
      );
}

/// Programme les notifications sans tâche de fond : à l'ouverture et à
/// chaque changement des données, les rappels des 30 prochains jours sont
/// reprogrammés ; un budget qui franchit un seuil déclenche une alerte
/// immédiate (une fois par niveau, par budget et par mois).
class NotificationScheduler extends Notifier<NotificationSettings> {
  Timer? _debounce;
  Future<void> _budgetCheck = Future.value();
  bool _ready = false;

  final AppLocalizations _l10n = lookupAppLocalizations(const Locale('fr'));

  NotificationService get _service => ref.read(notificationServiceProvider);
  NotificationPreferences get _prefs =>
      ref.read(notificationPreferencesProvider);

  @override
  NotificationSettings build() {
    ref
      ..onDispose(() => _debounce?.cancel())
      ..listen(recurringOperationsProvider, (_, _) => _rescheduleSoon())
      ..listen(plannedExpensesProvider, (_, _) => _rescheduleSoon())
      ..listen(
        backupControllerProvider.select((s) => s.lastAt),
        (_, _) => _rescheduleSoon(),
      )
      ..listen(forecastProvider(ForecastHorizon.month), (_, _) {
        _rescheduleSoon();
      })
      ..listen(budgetsOverviewProvider, (_, next) {
        if (next != null) _checkBudgets(next);
      });
    unawaited(_start());
    return const NotificationSettings();
  }

  Future<void> _start() async {
    final router = ref.read(appRouterProvider);
    await _service.initialize(router.go);
    try {
      state = NotificationSettings({
        for (final kind in NoticeKind.values)
          if (!await _prefs.isEnabled(kind)) kind,
      });
    } on Object catch (error, stack) {
      reportError(error, stack);
    }
    _ready = true;
    if (await _service.launchRoute() case final route?) router.go(route);
    _rescheduleSoon();
    if (ref.read(budgetsOverviewProvider) case final overview?) {
      _checkBudgets(overview);
    }
  }

  Future<void> setEnabled(NoticeKind kind, bool value) async {
    state = state.withKind(kind, value);
    try {
      await _prefs.setEnabled(kind, value);
    } on Object catch (error, stack) {
      reportError(error, stack);
    }
    _rescheduleSoon();
  }

  /// Regroupe les changements rapprochés (saisie de plusieurs opérations).
  void _rescheduleSoon() {
    if (!_ready) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      unawaited(_reschedule());
    });
  }

  Future<void> _reschedule() async {
    final now = ref.read(clockProvider)();
    final recurring = ref.read(recurringOperationsProvider).value ?? const [];
    final history = ref.read(spendingHistoryProvider).value;
    // Pas de prévision (ni d'alerte de solde bas) sans assez d'historique.
    final forecast =
        history != null && history.daysOfHistory(now) >= Forecast.minHistoryDays
        ? ref.read(forecastProvider(ForecastHorizon.month))
        : null;
    final notices = [
      if (state.isEnabled(NoticeKind.reminder))
        ...NotificationPlan.reminders(
          operations: recurring,
          now: now,
          l10n: _l10n,
          route: AppRoutes.recurring,
        ),
      if (state.isEnabled(NoticeKind.reminder))
        ...NotificationPlan.plannedReminders(
          expenses: ref.read(plannedExpensesProvider).value ?? const [],
          now: now,
          l10n: _l10n,
          route: AppRoutes.plannedDetail,
        ),
      if (state.isEnabled(NoticeKind.lowBalance))
        ?NotificationPlan.lowBalance(
          forecast: forecast,
          now: now,
          l10n: _l10n,
          route: AppRoutes.forecast,
        ),
      if (state.isEnabled(NoticeKind.backup))
        ?NotificationPlan.backupReminder(
          lastBackup: ref.read(backupControllerProvider).lastAt,
          firstOperation: history?.firstDay,
          now: now,
          l10n: _l10n,
          route: AppRoutes.settings,
        ),
    ];
    if (notices.isNotEmpty) await _askPermissionOnce();
    await _service.replaceScheduled(notices, _l10n);
  }

  void _checkBudgets(BudgetsOverview overview) {
    if (!_ready) return;
    _budgetCheck = _budgetCheck.then((_) async {
      try {
        final now = ref.read(clockProvider)();
        // Une fois par niveau, par budget et par mois budgétaire.
        final month = overview.month.toString();
        final notified = await _prefs.notifiedLevels(month);
        final crossings = NotificationPlan.budgetCrossings(
          overview: overview,
          notified: notified,
          now: now,
          l10n: _l10n,
          route: AppRoutes.budgets,
        );
        if (crossings.isEmpty) return;
        for (final (status, notice) in crossings) {
          // Niveau mémorisé même interrupteur coupé : pas de rafale le jour
          // où il est réactivé.
          notified[status.budget.id] = NotificationPlan.alertLevel(status);
          // Budget atteint ou dépassé : un avertissement haptique, une fois.
          if (NotificationPlan.alertLevel(status) == 2) {
            unawaited(Haptics.warning());
          }
          if (state.isEnabled(NoticeKind.budget)) {
            await _askPermissionOnce();
            await _service.show(notice, _l10n);
          }
        }
        await _prefs.saveNotifiedLevels(month, notified);
      } on Object catch (error, stack) {
        reportError(error, stack);
      }
    });
  }

  /// Autorisation demandée au premier besoin, une seule fois.
  Future<void> _askPermissionOnce() async {
    try {
      if (await _prefs.permissionAsked()) return;
      await _prefs.markPermissionAsked();
      await _service.requestPermission();
    } on Object catch (error, stack) {
      reportError(error, stack);
    }
  }
}

final notificationSchedulerProvider =
    NotifierProvider<NotificationScheduler, NotificationSettings>(
      NotificationScheduler.new,
    );
