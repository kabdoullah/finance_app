import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../l10n/l10n.dart';
import '../domain/transaction.dart';
import 'transaction_labels.dart';

/// Feuille « Nouvelle opération » ouverte par le bouton Ajouter : dicter,
/// choisir un type, ou écrire en texte libre. Scanner un reçu viendra plus
/// tard.
Future<void> showNewOperationSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final colors = sheetContext.colors;
        final l10n = sheetContext.l10n;
        return SafeArea(
          child: SingleChildScrollView(
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
                Material(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.push(AppRoutes.quickEntry());
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        spacing: 14,
                        children: [
                          Icon(
                            AppIcons.microphoneBold,
                            size: 22,
                            color: colors.surface,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 2,
                              children: [
                                Text(
                                  l10n.qeDictate,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colors.surface,
                                  ),
                                ),
                                Text(
                                  l10n.qeDictateHint,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.surface.withValues(
                                      alpha: 0.85,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                const SizedBox(height: 14),
                Text(
                  l10n.qeOrWrite,
                  style: TextStyle(fontSize: 13, color: colors.inkSecondary),
                ),
                const SizedBox(height: 6),
                Material(
                  color: colors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: colors.line),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.push(AppRoutes.quickEntry(text: true));
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.qeWriteExample,
                              style: TextStyle(
                                fontSize: 15,
                                color: colors.inkTertiary,
                              ),
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.primary,
                            ),
                            child: Icon(
                              AppIcons.arrowUpBold,
                              size: 16,
                              color: colors.surface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.qeWriteNote,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.inkTertiary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

/// Boutons flottants du design system, toujours au même endroit : « + »
/// (saisie à la main, ouvre la feuille ci-dessus) et « Dicter », le
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
          onPressed: () => showNewOperationSheet(context),
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
