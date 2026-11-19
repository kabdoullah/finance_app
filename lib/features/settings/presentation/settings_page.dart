import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../l10n/l10n.dart';
import '../../assistant/presentation/ai_model_controller.dart';
import '../../assistant/presentation/assistant_controller.dart';
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
                  style: TextStyle(fontSize: 14, color: colors.inkSecondary),
                ),
              ),
            ],
          ),
          _SectionLabel(l10n.settingsPrefsSection),
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
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.settingsHideAmountsHint,
              style: TextStyle(fontSize: 12.5, color: colors.inkTertiary),
            ),
          ),
          _SectionLabel(l10n.settingsNotifSection),
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
          ])
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: notifications.isEnabled(kind),
              onChanged: (value) => ref
                  .read(notificationSchedulerProvider.notifier)
                  .setEnabled(kind, value),
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                hint,
                style: TextStyle(fontSize: 12.5, color: colors.inkTertiary),
              ),
            ),
          _SectionLabel(l10n.settingsSecuritySection),
          const _LockSettings(),
          _SettingsRow(
            icon: AppIcons.shieldCheck,
            title: l10n.settingsPrivacy,
            subtitle: l10n.settingsPrivacyHint,
          ),
          _SectionLabel(l10n.settingsAiSection),
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
          _SettingsRow(
            icon: AppIcons.trash,
            title: l10n.settingsClearHistory,
            onTap: () => _clearHistory(context, ref),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.settingsFooter(l10n.appTitle, _appVersion),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colors.inkTertiary),
          ),
        ],
      ),
    );
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
    TextStyle subtitle() =>
        TextStyle(fontSize: 12.5, color: colors.inkTertiary);
    const title = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 4),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: context.colors.inkTertiary,
      ),
    ),
  );
}

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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle case final text?)
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 12.5,
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ok ? colors.onPrimarySoft : colors.inkSecondary,
                  ),
                ),
              ),
            if (value case final text?)
              Text(
                text,
                style: TextStyle(fontSize: 14, color: colors.inkSecondary),
              ),
            if (onTap != null)
              Icon(AppIcons.caretRight, size: 14, color: colors.inkTertiary),
          ],
        ),
      ),
    );
  }
}
