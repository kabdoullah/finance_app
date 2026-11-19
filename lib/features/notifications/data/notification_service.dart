import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/errors/error_reporter.dart';
import '../../../l10n/l10n.dart';
import '../domain/notification_plan.dart';

/// Notifications locales Android (aucun serveur). Hors Android ou en test,
/// chaque appel ne fait rien.
class NotificationService {
  NotificationService();

  final _plugin = FlutterLocalNotificationsPlugin();

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Prépare le paquet ; [onTap] reçoit l'écran à ouvrir.
  Future<void> initialize(void Function(String route) onTap) => _guard(
    () => _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload case final route? when route.isNotEmpty) {
          onTap(route);
        }
      },
    ),
  );

  /// Écran demandé si l'application a été lancée par une notification.
  Future<String?> launchRoute() async {
    final details = await _guard(_plugin.getNotificationAppLaunchDetails);
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  /// Autorisation d'Android 13+ (sans effet avant).
  Future<void> requestPermission() =>
      _guard(() async => _android?.requestNotificationsPermission());

  /// Remplace toutes les notifications programmées par [notices].
  Future<void> replaceScheduled(
    List<PlannedNotice> notices,
    AppLocalizations l10n,
  ) => _guard(() async {
    await _plugin.cancelAllPendingNotifications();
    for (final notice in notices) {
      await _plugin.zonedSchedule(
        id: notice.id,
        // Instant absolu : l'heure locale convertie en UTC.
        scheduledDate: tz.TZDateTime.from(notice.at.toUtc(), tz.UTC),
        notificationDetails: _details(notice.kind, l10n),
        // Pas d'alarme exacte (permission refusée par défaut sur Android
        // 14) : Android peut décaler de quelques minutes.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: notice.title,
        body: notice.body,
        payload: notice.route,
      );
    }
  });

  Future<void> show(PlannedNotice notice, AppLocalizations l10n) => _guard(
    () => _plugin.show(
      id: notice.id,
      title: notice.title,
      body: notice.body,
      notificationDetails: _details(notice.kind, l10n),
      payload: notice.route,
    ),
  );

  static NotificationDetails _details(NoticeKind kind, AppLocalizations l10n) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'finance_${kind.name}',
          switch (kind) {
            NoticeKind.reminder => l10n.ntChannelReminders,
            NoticeKind.budget => l10n.ntChannelBudgets,
            NoticeKind.lowBalance => l10n.ntChannelLowBalance,
          },
          channelDescription: switch (kind) {
            NoticeKind.reminder => l10n.ntChannelRemindersHint,
            NoticeKind.budget => l10n.ntChannelBudgetsHint,
            NoticeKind.lowBalance => l10n.ntChannelLowBalanceHint,
          },
          // Montants masqués sur l'écran verrouillé.
          visibility: NotificationVisibility.private,
        ),
      );

  static Future<T?> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on MissingPluginException {
      return null;
    } on Object catch (error, stack) {
      reportError(error, stack);
      return null;
    }
  }
}

/// Réglages et mémoire des notifications (pas des données financières :
/// hors base chiffrée).
class NotificationPreferences {
  const NotificationPreferences(this._prefs);

  final SharedPreferencesAsync _prefs;

  static String _enabledKey(NoticeKind kind) => 'notif.${kind.name}';
  static const _permissionKey = 'notif.permissionAsked';
  static String _levelsKey(String month) => 'notif.budgets.$month';

  Future<bool> isEnabled(NoticeKind kind) async =>
      await _prefs.getBool(_enabledKey(kind)) ?? true;

  Future<void> setEnabled(NoticeKind kind, bool value) =>
      _prefs.setBool(_enabledKey(kind), value);

  Future<bool> permissionAsked() async =>
      await _prefs.getBool(_permissionKey) ?? false;

  Future<void> markPermissionAsked() => _prefs.setBool(_permissionKey, true);

  /// Niveau d'alerte déjà signalé ce mois-ci, par budget.
  Future<Map<String, int>> notifiedLevels(String month) async {
    final raw = await _prefs.getString(_levelsKey(month));
    if (raw == null) return {};
    return (jsonDecode(raw) as Map).map((k, v) => MapEntry('$k', v as int));
  }

  Future<void> saveNotifiedLevels(String month, Map<String, int> levels) =>
      _prefs.setString(_levelsKey(month), jsonEncode(levels));
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final notificationPreferencesProvider = Provider<NotificationPreferences>(
  (ref) => NotificationPreferences(SharedPreferencesAsync()),
);
