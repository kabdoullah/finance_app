import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../l10n/l10n.dart';

/// Ouvre l'écran « Nouvelle opération » (type, montant, raccourcis
/// « Dicter » et « Écrire avec mes mots »).
void openNewOperation(BuildContext context) =>
    context.push(AppRoutes.newTransaction());

/// Boutons flottants du design system, toujours au même endroit : « + »
/// (saisie à la main, ouvre l'écran Nouvelle opération) et « Dicter », le
/// principal (la voix est privilégiée).
class AddOperationButton extends StatelessWidget {
  const AddOperationButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        FloatingActionButton(
          heroTag: 'add-operation',
          tooltip: l10n.txAdd,
          backgroundColor: colors.surface,
          foregroundColor: colors.ink,
          onPressed: () => openNewOperation(context),
          child: const Icon(AppIcons.plusBold, size: 20),
        ),
        FloatingActionButton.extended(
          heroTag: 'dictate',
          onPressed: () => context.push(AppRoutes.quickEntry()),
          icon: const Icon(AppIcons.microphoneBold, size: 18),
          label: Text(l10n.txEmptyDictate),
        ),
      ],
    );
  }
}
