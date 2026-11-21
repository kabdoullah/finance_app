import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../l10n/l10n.dart';

/// Boîte de confirmation des maquettes : titre, explication, action principale
/// puis « Annuler ». Retourne `true` si l'utilisateur confirme.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colors = context.colors;
      return Dialog(
        insetPadding: const EdgeInsets.all(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Text(title, style: AppText.sheetTitle),
              Text(
                message,
                style: AppText.body.prose.copyWith(color: colors.inkSecondary),
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: colors.negative,
                        foregroundColor: colors.onPrimary,
                      )
                    : null,
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(context.l10n.cancel),
              ),
            ],
          ),
        ),
      );
    },
  );
  return confirmed ?? false;
}
