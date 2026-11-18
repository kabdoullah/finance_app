import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../l10n/l10n.dart';
import '../../assistant/presentation/ai_model_controller.dart';
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
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 4),
            child: Text(
              l10n.settingsAiSection.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: colors.inkTertiary,
              ),
            ),
          ),
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
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.status,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12.5, color: colors.inkTertiary),
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
