import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/clock.dart';
import '../../../core/errors/error_reporter.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/time/month.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/section_label.dart';
import '../../../l10n/l10n.dart';
import '../../assistant/presentation/ai_model_controller.dart';
import '../../assistant/presentation/assistant_controller.dart';
import '../../backup/data/backup_file.dart';
import '../../backup/presentation/backup_controller.dart';
import '../../backup/presentation/backup_password_dialog.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_providers.dart';
import '../../notifications/domain/notification_plan.dart';
import '../../notifications/presentation/notification_scheduler.dart';
import '../../quick_entry/data/speech_service.dart';
import '../../recurring/presentation/recurring_providers.dart';
import '../../security/domain/pin_policy.dart';
import '../../security/presentation/lock_controller.dart';
import '../../security/presentation/pin_flow_page.dart';
import 'settings_providers.dart';

/// Paramètres (maquette Paramètres) : préférences, notifications,
/// confidentialité et assistant IA. Le verrouillage et la sauvegarde
/// viendront ensuite.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final ai = ref.watch(aiModelControllerProvider).status;
    final voice = ref.watch(speechAvailabilityProvider).value;
    final notifications = ref.watch(notificationSchedulerProvider);
    final themeMode = ref.watch(themeModeProvider);
    int visible(List<CategoryGroup>? groups) =>
        groups?.where((g) => !g.category.isHidden).length ?? 0;
    final categoryCount =
        visible(ref.watch(categoryGroupsProvider(CategoryKind.expense)).value) +
        visible(ref.watch(categoryGroupsProvider(CategoryKind.income)).value);
    final activeRecurring =
        (ref.watch(recurringOperationsProvider).value ?? const [])
            .where((o) => o.isActive)
            .length;

    final (aiLabel, aiOk) = switch (ai) {
      AiModelStatus.ready => (l10n.aiStatusReady, true),
      AiModelStatus.installed => (l10n.aiStatusInstalled, false),
      AiModelStatus.downloading => (l10n.aiStatusDownloading, true),
      AiModelStatus.loading => (l10n.aiStatusLoading, true),
      AiModelStatus.error => (l10n.aiStatusError, false),
      AiModelStatus.notInstalled => (l10n.aiStatusNone, false),
      AiModelStatus.unavailable => (l10n.aiStatusUnavailable, false),
      AiModelStatus.checking => ('…', false),
    };
    final (voiceLabel, voiceOk) = switch (voice) {
      SpeechAvailability.ready ||
      SpeechAvailability.unknown => (l10n.settingsVoiceReady, true),
      SpeechAvailability.downloading => (l10n.aiVoiceDownloading, false),
      SpeechAvailability.missingLanguage => (l10n.aiVoiceMissing, false),
      SpeechAvailability.unsupported => (l10n.aiVoiceUnavailable, false),
      null => ('…', false),
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        children: [
          Row(
            spacing: 10,
            children: [
              Icon(AppIcons.lockSimple, size: 18, color: colors.inkSecondary),
              Expanded(
                child: Text(
                  l10n.settingsLocalOnly,
                  style: AppText.body.copyWith(color: colors.inkSecondary),
                ),
              ),
            ],
          ),
          SectionLabel(l10n.settingsPrefsSection),
          _SettingsRow(
            icon: AppIcons.money,
            title: l10n.settingsCurrency,
            value: l10n.settingsCurrencyValue,
          ),
          _SettingsRow(
            icon: AppIcons.globeSimple,
            title: l10n.settingsLanguage,
            value: l10n.settingsLanguageValue,
          ),
          _SettingsRow(
            icon: AppIcons.palette,
            title: l10n.settingsTheme,
            value: _themeLabel(themeMode, l10n),
            onTap: () => _chooseTheme(context, ref, themeMode),
          ),
          _SettingsRow(
            icon: AppIcons.tag,
            title: l10n.categoriesTitle,
            subtitle: l10n.settingsCategoriesHint,
            value: '$categoryCount',
            onTap: () => context.push(AppRoutes.categories),
          ),
          _SettingsRow(
            icon: AppIcons.calendarBlank,
            title: l10n.settingsMonthStart,
            subtitle: l10n.settingsMonthStartHint,
            value: _monthStartLabel(ref.watch(budgetMonthStartProvider), l10n),
            onTap: () => _chooseMonthStart(context, ref),
          ),
          _SettingsRow(
            icon: AppIcons.repeat,
            title: l10n.settingsRecurring,
            value: l10n.settingsRecurringCount(activeRecurring),
            onTap: () => context.go(AppRoutes.recurring),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: ref.watch(hideAmountsSettingProvider),
            onChanged: ref.read(hideAmountsSettingProvider.notifier).set,
            title: Text(
              l10n.settingsHideAmounts,
              style: AppText.bodyLarge.semibold,
            ),
            subtitle: Text(
              l10n.settingsHideAmountsHint,
              style: AppText.caption.copyWith(color: colors.inkTertiary),
            ),
          ),
          SectionLabel(l10n.settingsNotifSection),
          for (final (kind, title, hint) in [
            (
              NoticeKind.reminder,
              l10n.ntChannelReminders,
              l10n.ntChannelRemindersHint,
            ),
            (
              NoticeKind.budget,
              l10n.ntChannelBudgets,
              l10n.ntChannelBudgetsHint,
            ),
            (
              NoticeKind.lowBalance,
              l10n.ntChannelLowBalance,
              l10n.ntChannelLowBalanceHint,
            ),
            (NoticeKind.backup, l10n.ntChannelBackup, l10n.ntChannelBackupHint),
          ])
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: notifications.isEnabled(kind),
              onChanged: (value) => ref
                  .read(notificationSchedulerProvider.notifier)
                  .setEnabled(kind, value),
              title: Text(title, style: AppText.bodyLarge.semibold),
              subtitle: Text(
                hint,
                style: AppText.caption.copyWith(color: colors.inkTertiary),
              ),
            ),
          SectionLabel(l10n.settingsSecuritySection),
          const _LockSettings(),
          _SettingsRow(
            icon: AppIcons.shieldCheck,
            title: l10n.settingsPrivacy,
            subtitle: l10n.settingsPrivacyHint,
          ),
          SectionLabel(l10n.bkSection),
          const _BackupSettings(),
          SectionLabel(l10n.settingsAiSection),
          _SettingsRow(
            icon: AppIcons.chatCircleText,
            title: l10n.settingsAiModel,
            subtitle: l10n.settingsAiModelHint,
            status: (aiLabel, aiOk),
            onTap: () => context.push(AppRoutes.aiModel),
          ),
          _SettingsRow(
            icon: AppIcons.microphoneBold,
            title: l10n.settingsVoice,
            subtitle: l10n.settingsVoiceHint,
            status: (voiceLabel, voiceOk),
            onTap: () => context.push(AppRoutes.aiModel),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: ref.watch(suggestionsSettingProvider),
            onChanged: ref.read(suggestionsSettingProvider.notifier).set,
            title: Text(
              l10n.settingsSuggestions,
              style: AppText.bodyLarge.semibold,
            ),
            subtitle: Text(
              l10n.settingsSuggestionsHint,
              style: AppText.caption.copyWith(color: colors.inkTertiary),
            ),
          ),
          _SettingsRow(
            icon: AppIcons.trash,
            title: l10n.settingsClearHistory,
            onTap: () => _clearHistory(context, ref),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.settingsFooter(l10n.appTitle, _appVersion),
            textAlign: TextAlign.center,
            style: AppText.small.copyWith(color: colors.inkTertiary),
          ),
        ],
      ),
    );
  }
}

String _monthStartLabel(int day, AppLocalizations l10n) =>
    day == 1 ? l10n.settingsMonthStartFirst : l10n.settingsMonthStartDay(day);

Future<void> _chooseMonthStart(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final current = ref.read(budgetMonthStartProvider);
  final picked = await showDialog<int>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.settingsMonthStart),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            l10n.settingsMonthStartExplain,
            style: AppText.bodySmall.prose.copyWith(
              color: context.colors.inkSecondary,
            ),
          ),
        ),
        for (var day = 1; day <= Month.maxStartDay; day++)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(day),
            child: Row(
              spacing: 12,
              children: [
                Expanded(child: Text(_monthStartLabel(day, l10n))),
                if (day == current) const Icon(AppIcons.checkBold, size: 18),
              ],
            ),
          ),
      ],
    ),
  );
  if (picked != null) {
    await ref.read(budgetMonthStartProvider.notifier).set(picked);
  }
}

/// Version affichée en pied de page (pubspec : 1.0.0).
const _appVersion = '1.0';

String _themeLabel(ThemeMode mode, AppLocalizations l10n) => switch (mode) {
  ThemeMode.system => l10n.settingsThemeSystem,
  ThemeMode.light => l10n.settingsThemeLight,
  ThemeMode.dark => l10n.settingsThemeDark,
};

Future<void> _chooseTheme(
  BuildContext context,
  WidgetRef ref,
  ThemeMode current,
) async {
  final l10n = context.l10n;
  final picked = await showDialog<ThemeMode>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.settingsTheme),
      children: [
        for (final mode in ThemeMode.values)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(mode),
            child: Row(
              spacing: 12,
              children: [
                Expanded(child: Text(_themeLabel(mode, l10n))),
                if (mode == current) const Icon(AppIcons.checkBold, size: 18),
              ],
            ),
          ),
      ],
    ),
  );
  if (picked != null) await ref.read(themeModeProvider.notifier).set(picked);
}

Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final confirmed = await showConfirmDialog(
    context,
    title: l10n.settingsClearHistoryTitle,
    message: l10n.settingsClearHistoryBody,
    confirmLabel: l10n.settingsClearHistoryConfirm,
    destructive: true,
  );
  if (!confirmed) return;
  await ref.read(assistantControllerProvider.notifier).clearHistory();
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.settingsHistoryCleared)));
  }
}

/// Sauvegarde chiffrée, restauration et Google Drive (à venir).
class _BackupSettings extends ConsumerWidget {
  const _BackupSettings();

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final password = await showBackupPasswordDialog(context, create: true);
    if (password == null) return;
    final saved = await ref
        .read(backupControllerProvider.notifier)
        .backup(password);
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.bkDone)));
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final controller = ref.read(backupControllerProvider.notifier);
    void say(String text) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(text)));
      }
    }

    final bytes = await controller.pickBackup();
    if (bytes == null || !context.mounted) return;
    final password = await showBackupPasswordDialog(context, create: false);
    if (password == null || !context.mounted) return;
    final BackupInfo info;
    try {
      info = await controller.inspect(bytes, password);
    } on BackupException catch (e) {
      say(switch (e.error) {
        BackupError.unreadable => l10n.bkUnreadable,
        BackupError.tooNew => l10n.bkTooNew,
      });
      return;
    }
    if (!context.mounted) return;
    final day = AppDateFormat.dayMonth(info.createdAt, locale);
    final confirmed = await showConfirmDialog(
      context,
      title: AppDateFormat.sentence(l10n.bkConfirmTitle(day)),
      message: l10n.bkConfirmBody(
        day,
        DateFormat.Hm(locale).format(info.createdAt),
      ),
      confirmLabel: l10n.bkConfirm,
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await controller.restore(bytes, password);
      say(l10n.bkRestored);
    } on Object catch (error, stack) {
      reportError(error, stack);
      say(l10n.bkRestoreFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final backup = ref.watch(backupControllerProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = ref.watch(clockProvider)();
    final subtitle = switch (backup) {
      BackupState(activity: BackupActivity.saving) => l10n.bkSaving,
      BackupState(activity: BackupActivity.restoring) => l10n.bkRestoring,
      BackupState(:final lastAt?, :final lastSize) => l10n.bkLast(
        RelativeDate.capitalize(RelativeDate(l10n, locale, now).day(lastAt)),
        DateFormat.Hm(locale).format(lastAt),
        _formatSize(lastSize ?? 0),
      ),
      _ => l10n.bkNever,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsRow(
          icon: AppIcons.cloudArrowUp,
          title: l10n.bkBackup,
          subtitle: subtitle,
          onTap: backup.busy ? null : () => _backup(context, ref),
        ),
        if (backup.failure case final failure?)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
            decoration: BoxDecoration(
              color: colors.negativeSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  failure == BackupFailure.storageFull
                      ? l10n.bkFailedStorage
                      : l10n.bkFailedOther,
                  style: AppText.bodySmall.prose,
                ),
                TextButton(
                  onPressed: () => _backup(context, ref),
                  child: Text(l10n.bkRetry),
                ),
              ],
            ),
          ),
        _SettingsRow(
          icon: AppIcons.clockCounterClockwise,
          title: l10n.bkRestore,
          subtitle: l10n.bkRestoreHint,
          onTap: backup.busy ? null : () => _restore(context, ref),
        ),
        _SettingsRow(
          icon: AppIcons.export,
          title: l10n.exExport,
          subtitle: l10n.exExportHint,
          onTap: () => context.push(AppRoutes.export),
        ),
        _SettingsRow(
          icon: AppIcons.googleDriveLogo,
          title: l10n.bkDrive,
          subtitle: l10n.bkDriveHint,
          value: l10n.bkComingSoon,
        ),
      ],
    );
  }

  /// « 2,4 Mo », « 850 ko ».
  static String _formatSize(int bytes) {
    if (bytes < 1000 * 1000) return '${(bytes / 1000).ceil()} ko';
    return '${(bytes / 1000000).toStringAsFixed(1).replaceAll('.', ',')} Mo';
  }
}

/// Verrouillage par code, biométrie et délai.
class _LockSettings extends ConsumerWidget {
  const _LockSettings();

  Future<void> _toggle(BuildContext context, bool enable) => context.push<bool>(
    AppRoutes.pin(enable ? PinFlow.create.name : PinFlow.disable.name),
  );

  Future<void> _biometric(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final l10n = context.l10n;
    final ok = await ref
        .read(lockControllerProvider.notifier)
        .setBiometric(value, l10n.lockBiometricReason);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.settingsBiometricFailed)));
    }
  }

  Future<void> _delay(
    BuildContext context,
    WidgetRef ref,
    LockDelay current,
  ) async {
    final l10n = context.l10n;
    final picked = await showDialog<LockDelay>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.settingsLockDelay),
        children: [
          for (final delay in LockDelay.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(delay),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(child: Text(_delayLabel(delay, l10n))),
                  if (delay == current)
                    const Icon(AppIcons.checkBold, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked != null) {
      await ref.read(lockControllerProvider.notifier).setDelay(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final lock = ref.watch(lockControllerProvider);
    TextStyle subtitle() => AppText.caption.copyWith(color: colors.inkTertiary);
    final title = AppText.bodyLarge.semibold;
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: lock.enabled,
          onChanged: lock.loaded ? (value) => _toggle(context, value) : null,
          title: Text(l10n.settingsLock, style: title),
          subtitle: Text(l10n.settingsLockHint, style: subtitle()),
        ),
        if (lock.enabled) ...[
          _SettingsRow(
            icon: AppIcons.lockKey,
            title: l10n.settingsPin,
            value: l10n.settingsPinChange,
            onTap: () => context.push<bool>(AppRoutes.pin(PinFlow.change.name)),
          ),
          if (lock.biometricAvailable)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: lock.biometric,
              onChanged: (value) => _biometric(context, ref, value),
              title: Text(l10n.settingsBiometric, style: title),
              subtitle: Text(l10n.settingsBiometricHint, style: subtitle()),
            ),
          _SettingsRow(
            icon: AppIcons.clock,
            title: l10n.settingsLockDelay,
            value: _delayLabel(lock.delay, l10n),
            onTap: () => _delay(context, ref, lock.delay),
          ),
        ],
      ],
    );
  }
}

String _delayLabel(LockDelay delay, AppLocalizations l10n) => switch (delay) {
  LockDelay.immediately => l10n.lockDelayImmediately,
  LockDelay.oneMinute => l10n.lockDelayOneMinute,
  LockDelay.fiveMinutes => l10n.lockDelayFiveMinutes,
};

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.onTap,
    this.subtitle,
    this.value,
    this.status,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Valeur affichée à droite (« FCFA (XOF) », « 3 actives »).
  final String? value;

  /// `null` : ligne d'information, sans chevron.
  final VoidCallback? onTap;

  /// Pastille d'état : libellé, et vrai si l'état est « bon ».
  final (String, bool)? status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.chip,
              ),
              child: Icon(icon, size: 18, color: colors.ink),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(title, style: AppText.bodyLarge.semibold),
                  if (subtitle case final text?)
                    Text(
                      text,
                      style: AppText.caption.copyWith(
                        color: colors.inkTertiary,
                      ),
                    ),
                ],
              ),
            ),
            if (status case (final label, final ok))
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ok ? colors.primarySoft : colors.chip,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: AppText.small.semibold.copyWith(
                    color: ok ? colors.onPrimarySoft : colors.inkSecondary,
                  ),
                ),
              ),
            if (value case final text?)
              Text(
                text,
                style: AppText.body.copyWith(color: colors.inkSecondary),
              ),
            if (onTap != null)
              Icon(AppIcons.caretRight, size: 14, color: colors.inkTertiary),
          ],
        ),
      ),
    );
  }
}
