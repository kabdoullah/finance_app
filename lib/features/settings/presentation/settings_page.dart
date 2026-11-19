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
import '../../notifications/domain/notification_plan.dart';
import '../../notifications/presentation/notification_scheduler.dart';
import '../../quick_entry/data/speech_service.dart';

/// Paramètres : catégories et assistant IA. Le reste (sécurité,
/// sauvegarde…) viendra avec la fonctionnalité « Sécurité et paramètres ».
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final ai = ref.watch(aiModelControllerProvider).status;
    final voice = ref.watch(speechAvailabilityProvider).value;
    final notifications = ref.watch(notificationSchedulerProvider);

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
          _SettingsRow(
            icon: AppIcons.tag,
            title: l10n.categoriesTitle,
            subtitle: l10n.settingsCategoriesHint,
            onTap: () => context.push(AppRoutes.categories),
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
        ],
      ),
    );
  }
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
    required this.onTap,
    this.subtitle,
    this.status,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

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
            Icon(AppIcons.caretRight, size: 14, color: colors.inkTertiary),
          ],
        ),
      ),
    );
  }
}
