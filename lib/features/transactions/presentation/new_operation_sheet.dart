import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../l10n/l10n.dart';
import '../domain/transaction.dart';
import 'transaction_labels.dart';

/// Feuille « Nouvelle opération » ouverte par le bouton Ajouter.
/// Dicter, Scanner un reçu et la saisie en texte libre arriveront avec l'IA.
Future<void> showNewOperationSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final colors = sheetContext.colors;
        final l10n = sheetContext.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.txNewTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(sheetContext)
                          .closeButtonTooltip,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(AppIcons.xBold, size: 16),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.chip,
                        foregroundColor: colors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                for (final kind in TransactionKind.values)
                  InkWell(
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.push(AppRoutes.newTransaction(kind: kind));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: colors.line)),
                      ),
                      child: Row(
                        spacing: 14,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.chip,
                            ),
                            child: Icon(kind.icon, size: 20, color: colors.ink),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 2,
                              children: [
                                Text(
                                  kind.label(l10n),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  kind.hint(l10n),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.inkTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(AppIcons.caretRight, color: colors.inkTertiary),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

/// Bouton flottant « Ajouter » des maquettes (ouvre la feuille ci-dessus).
class AddOperationButton extends StatelessWidget {
  const AddOperationButton({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
    onPressed: () => showNewOperationSheet(context),
    icon: const Icon(AppIcons.plusBold, size: 18),
    label: Text(context.l10n.txAdd),
  );
}
