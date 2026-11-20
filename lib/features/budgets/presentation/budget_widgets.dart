import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/motion.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/l10n.dart';
import '../domain/budget.dart';
import 'budgets_providers.dart';

/// Couleur de barre : vert, ambre au seuil choisi, brique au-delà de 100 %.
Color budgetBarColor(BudgetLevel level, AppColors colors) => switch (level) {
  BudgetLevel.ok || BudgetLevel.reached => colors.primary,
  BudgetLevel.warning => colors.warning,
  BudgetLevel.exceeded => colors.negative,
};

/// « 27 500 restants », « Dépassé de 3 000 » ou « Payé ».
(String, Color) budgetStatusLabel(
  BudgetStatus status,
  AppLocalizations l10n,
  AppColors colors,
) => switch (status.level) {
  BudgetLevel.exceeded => (
    l10n.budgetExceeded(MoneyFormat.amount(-status.remaining)),
    colors.negative,
  ),
  BudgetLevel.reached => (l10n.budgetPaid, colors.inkSecondary),
  BudgetLevel.warning => (
    l10n.budgetRemaining(MoneyFormat.amount(status.remaining)),
    colors.warning,
  ),
  BudgetLevel.ok => (
    l10n.budgetRemaining(MoneyFormat.amount(status.remaining)),
    colors.inkSecondary,
  ),
};

class BudgetBar extends StatelessWidget {
  const BudgetBar({required this.status, this.height = 6, super.key});

  final BudgetStatus status;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = (status.spent.value / status.budget.limit.value).clamp(
      0.0,
      1.0,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: colors.chip,
          child: Align(
            alignment: Alignment.centerLeft,
            // Remplissage depuis la gauche à l'apparition.
            child: FillIn(
              value: fill,
              builder: (context, value) => FractionallySizedBox(
                widthFactor: value,
                heightFactor: 1,
                // Sauge → ambre → brique : la couleur change en 300 ms.
                child: AnimatedContainer(
                  duration: Motion.of(context, Motion.slow),
                  curve: Motion.ease,
                  color: budgetBarColor(status.level, colors),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ligne « Alimentation · 27 500 restants / 92 500 sur 120 000 » + barre.
class BudgetRow extends StatelessWidget {
  const BudgetRow({
    required this.status,
    this.onTap,
    this.showAmounts = true,
    this.masked = false,
    super.key,
  });

  final BudgetStatus status;
  final VoidCallback? onTap;

  /// « 92 500 sur 120 000 » sous la barre (masqué sur l'accueil).
  final bool showAmounts;

  /// Reste remplacé par « •••• » (la barre reste visible).
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final (statusLabel, labelColor) = budgetStatusLabel(status, l10n, colors);
    final label = masked ? MoneyFormat.masked : statusLabel;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    status.budget.category?.name ?? l10n.budgetAllExpenses,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
              ],
            ),
            BudgetBar(status: status),
            if (showAmounts)
              Text(
                l10n.budgetSpentOf(
                  MoneyFormat.amount(status.spent),
                  MoneyFormat.amount(status.budget.limit),
                ),
                style: TextStyle(fontSize: 12.5, color: colors.inkTertiary),
              ),
          ],
        ),
      ),
    );
  }
}

/// Message de budget à la confirmation d'une dépense (maquette
/// Ajout-Transaction) : reste ou dépassement du budget de la catégorie.
class BudgetImpactNote extends ConsumerWidget {
  const BudgetImpactNote({required this.mainCategoryId, super.key});

  final String mainCategoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final status = ref
        .watch(budgetsOverviewProvider)
        ?.categories
        .where((s) => s.budget.category?.id == mainCategoryId)
        .firstOrNull;
    if (status == null) return const SizedBox.shrink();

    final name = status.budget.category!.name;
    final exceeded = status.level == BudgetLevel.exceeded;
    final (bg, fg) = exceeded
        ? (colors.warningSoft, colors.warning)
        : (colors.primarySoft, colors.onPrimarySoft);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Icon(AppIcons.info, size: 17, color: fg),
          Expanded(
            child: Text(
              exceeded
                  ? l10n.budgetImpactOver(
                      name,
                      MoneyFormat.amount(-status.remaining),
                    )
                  : l10n.budgetImpactLeft(
                      MoneyFormat.amount(status.remaining),
                      name,
                    ),
              style: TextStyle(fontSize: 13.5, height: 1.45, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
