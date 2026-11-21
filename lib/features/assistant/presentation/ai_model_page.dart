import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../l10n/l10n.dart';
import '../../quick_entry/data/speech_service.dart';
import '../domain/ai_compatibility.dart';
import 'ai_model_controller.dart';

/// Écran « Modèle IA » (maquette IA-Modele) : installer, charger, libérer ou
/// supprimer Gemma 4, et état de la dictée.
class AiModelPage extends ConsumerWidget {
  const AiModelPage({super.key});

  Future<void> _install(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(aiModelControllerProvider.notifier);
    final l10n = context.l10n;
    switch (await controller.checkDownload()) {
      case DownloadCheck.notEnoughStorage:
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.aiNoStorage)));
        }
        return;
      case DownloadCheck.metered:
        if (!context.mounted) return;
        final confirmed = await showConfirmDialog(
          context,
          title: l10n.aiMeteredTitle,
          message: l10n.aiMeteredBody,
          confirmLabel: l10n.aiMeteredConfirm,
        );
        if (!confirmed) return;
      case DownloadCheck.ok:
        break;
    }
    await controller.download();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.aiDeleteTitle,
      message: l10n.aiDeleteBody,
      confirmLabel: l10n.aiDeleteConfirm,
      destructive: true,
    );
    if (confirmed) await ref.read(aiModelControllerProvider.notifier).delete();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final state = ref.watch(aiModelControllerProvider);
    final controller = ref.read(aiModelControllerProvider.notifier);
    final locale = Localizations.localeOf(context).toLanguageTag();

    final (pill, pillBg, pillFg) = switch (state.status) {
      AiModelStatus.ready => (
        l10n.aiStatusReady,
        colors.primarySoft,
        colors.onPrimarySoft,
      ),
      AiModelStatus.downloading || AiModelStatus.loading => (
        state.status == AiModelStatus.loading
            ? l10n.aiStatusLoading
            : l10n.aiStatusDownloading,
        colors.primarySoft,
        colors.onPrimarySoft,
      ),
      AiModelStatus.error => (
        l10n.aiStatusError,
        colors.negativeSoft,
        colors.negative,
      ),
      AiModelStatus.installed => (
        l10n.aiStatusInstalled,
        colors.chip,
        colors.inkSecondary,
      ),
      AiModelStatus.notInstalled => (
        l10n.aiStatusNone,
        colors.chip,
        colors.inkSecondary,
      ),
      AiModelStatus.unavailable => (
        l10n.aiStatusUnavailable,
        colors.chip,
        colors.inkSecondary,
      ),
      AiModelStatus.checking => (
        l10n.aiStatusChecking,
        colors.chip,
        colors.inkSecondary,
      ),
    };
    final description = switch (state.status) {
      AiModelStatus.checking => l10n.aiDescChecking,
      AiModelStatus.unavailable => [
        l10n.aiDescUnavailable,
        for (final reason in state.incompatibilities)
          switch (reason) {
            AiIncompatibility.systemTooOld => l10n.aiReasonSystem,
            AiIncompatibility.not64Bit => l10n.aiReason64Bit,
            AiIncompatibility.notEnoughRam => l10n.aiReasonRam,
          },
      ].join(' '),
      AiModelStatus.notInstalled => l10n.aiDescNone,
      AiModelStatus.downloading => l10n.aiDescDownloading,
      AiModelStatus.installed => l10n.aiDescInstalled,
      AiModelStatus.loading => l10n.aiDescLoading,
      AiModelStatus.ready => l10n.aiDescReady,
      AiModelStatus.error => l10n.aiDescError,
    };
    final notice = switch (state.notice) {
      AiModelNotice.lowMemory => l10n.aiLowMemory,
      AiModelNotice.downloadFailed => l10n.aiDownloadFailed,
      null => null,
    };
    final received = (AiRequirements.modelBytes * state.progress / 100 / 1e9)
        .toStringAsFixed(1)
        .replaceAll('.', locale.startsWith('fr') ? ',' : '.');

    final (primaryLabel, onPrimary) = switch (state.status) {
      AiModelStatus.notInstalled => (
        l10n.aiInstall,
        () => _install(context, ref),
      ),
      AiModelStatus.installed => (l10n.aiLoadNow, controller.load),
      AiModelStatus.ready => (l10n.aiUnload, controller.unload),
      AiModelStatus.error => (l10n.aiRetry, controller.load),
      _ => (null, null),
    };
    final (secondaryLabel, onSecondary) = switch (state.status) {
      AiModelStatus.downloading => (
        l10n.aiCancelDownload,
        controller.cancelDownload,
      ),
      AiModelStatus.error => (l10n.aiContinueWithout, controller.dismissError),
      _ => (null, null),
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiModelTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          Row(
            spacing: 14,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primarySoft,
                ),
                child: Icon(
                  AppIcons.chatCircleText,
                  size: 22,
                  color: colors.onPrimarySoft,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(l10n.aiModelName, style: AppText.sheetTitle),
                    Text(
                      l10n.aiModelMeta,
                      style: AppText.label.copyWith(color: colors.inkSecondary),
                    ),
                  ],
                ),
              ),
              _Pill(label: pill, background: pillBg, foreground: pillFg),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: AppText.bodyLarge.prose.copyWith(color: colors.inkSecondary),
          ),
          if (state.status == AiModelStatus.downloading ||
              state.status == AiModelStatus.loading) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: state.status == AiModelStatus.loading
                    ? null
                    : state.progress / 100,
                minHeight: 8,
                backgroundColor: colors.chip,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.status == AiModelStatus.loading
                  ? l10n.aiLoadingBar
                  : l10n.aiProgress(received, state.progress),
              style: AppText.label.copyWith(color: colors.inkSecondary),
            ),
          ],
          if (notice != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.warningSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Icon(
                    AppIcons.warningCircleBold,
                    size: 18,
                    color: colors.warning,
                  ),
                  Expanded(child: Text(notice, style: AppText.body.prose)),
                ],
              ),
            ),
          ],
          if (primaryLabel != null || secondaryLabel != null) ...[
            const SizedBox(height: 20),
            if (primaryLabel != null)
              FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel),
              ),
            ],
          ],
          const SizedBox(height: 28),
          _RoleRow(
            icon: AppIcons.chatCircleText,
            title: l10n.aiModelName,
            body: l10n.aiRoleGemma,
          ),
          _RoleRow(
            icon: AppIcons.chartLine,
            title: l10n.aiRoleAppTitle,
            body: l10n.aiRoleApp,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.aiWithout,
            style: AppText.label.prose.copyWith(color: colors.inkTertiary),
          ),
          _SectionLabel(l10n.aiVoiceSection),
          const _VoiceEngineRow(),
          _InfoRow(
            title: l10n.aiVoiceLanguage,
            trailing: Text(l10n.aiVoiceFrench, style: AppText.body.semibold),
          ),
          if (state.isInstalled) ...[
            _SectionLabel(l10n.aiPrefsSection),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: state.loadOnStartup,
              onChanged: controller.setLoadOnStartup,
              title: Text(
                l10n.aiLoadOnStartup,
                style: AppText.bodyLarge.semibold,
              ),
              subtitle: Text(
                l10n.aiLoadOnStartupHint,
                style: AppText.caption.copyWith(color: colors.inkTertiary),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: state.status == AiModelStatus.loading
                  ? null
                  : () => _delete(context, ref),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  spacing: 12,
                  children: [
                    Icon(AppIcons.trash, size: 20, color: colors.negative),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(
                            l10n.aiDelete,
                            style: AppText.bodyLarge.semibold.copyWith(
                              color: colors.negative,
                            ),
                          ),
                          Text(
                            l10n.aiDeleteHint,
                            style: AppText.caption.copyWith(
                              color: colors.inkTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: AppText.small.semibold.copyWith(color: foreground),
    ),
  );
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.chip,
            ),
            child: Icon(icon, size: 17, color: colors.ink),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(title, style: AppText.bodyLarge.semibold),
                Text(
                  body,
                  style: AppText.bodySmall.prose.copyWith(
                    color: colors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 4),
    child: Text(
      label.toUpperCase(),
      style: AppText.overline.copyWith(color: context.colors.inkTertiary),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.trailing, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(title, style: AppText.bodyLarge.semibold),
                if (subtitle case final text?)
                  Text(
                    text,
                    style: AppText.caption.copyWith(color: colors.inkTertiary),
                  ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

/// État réel de la dictée hors ligne.
class _VoiceEngineRow extends ConsumerWidget {
  const _VoiceEngineRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final availability = ref.watch(speechAvailabilityProvider).value;
    final (label, ok) = switch (availability) {
      SpeechAvailability.ready ||
      SpeechAvailability.unknown => (l10n.aiVoiceReady, true),
      SpeechAvailability.downloading => (l10n.aiVoiceDownloading, false),
      SpeechAvailability.missingLanguage => (l10n.aiVoiceMissing, false),
      SpeechAvailability.unsupported => (l10n.aiVoiceUnavailable, false),
      null => ('…', false),
    };
    return _InfoRow(
      title: l10n.aiVoiceEngine,
      subtitle: l10n.aiVoiceEngineHint,
      trailing: _Pill(
        label: label,
        background: ok ? colors.primarySoft : colors.chip,
        foreground: ok ? colors.onPrimarySoft : colors.inkSecondary,
      ),
    );
  }
}
