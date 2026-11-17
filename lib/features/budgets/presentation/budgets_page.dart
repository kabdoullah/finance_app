import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/clock.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/money/money.dart';
import '../../../core/time/month.dart';
import '../../../l10n/l10n.dart';
import '../domain/budget.dart';
import 'budget_widgets.dart';
import 'budgets_providers.dart';

/// Onglet Budgets (maquette Budgets) : budget du mois, alertes, budgets par
/// catégorie et catégories sans budget.
class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final overview = ref.watch(budgetsOverviewProvider);
    final now = ref.watch(clockProvider)();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.budgetsTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (overview != null) ...[
              if (overview.global case final global?)
                _MonthBudget(status: global, now: now)
              else
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.newBudget),
                  icon: const Icon(AppIcons.plusBold, size: 16),
                  label: Text(l10n.budgetNoGlobal),
                ),
              for (final status in overview.exceeded)
                if (!status.budget.isGlobal)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _Alert(
                      text: l10n.budgetExceededAlert(
                        status.budget.category!.name,
                        MoneyFormat.amount(-status.remaining),
                      ),
                    ),
                  ),
              const SizedBox(height: 28),
              if (overview.categories.isEmpty && overview.global == null)
                Text(
                  l10n.budgetEmpty,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colors.inkSecondary,
                  ),
                )
              else if (overview.categories.isNotEmpty) ...[
                Semantics(
                  header: true,
                  child: Text(
                    l10n.budgetByCategory,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                for (final status in overview.categories)
                  BudgetRow(
                    status: status,
                    onTap: () =>
                        context.push(AppRoutes.editBudget(status.budget.id)),
                  ),
              ],
              if (overview.withoutBudget.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.budgetWithout(
                    overview.withoutBudget.map((c) => c.name).join(', '),
                  ),
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: colors.inkTertiary,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.newBudget),
                icon: const Icon(AppIcons.plusBold, size: 18),
                label: Text(l10n.budgetCreate),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.transactions),
                child: Text(l10n.budgetSeeOperations),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// « Budget de novembre » : dépensé / limite, barre, reste par jour.
class _MonthBudget extends StatelessWidget {
  const _MonthBudget({required this.status, required this.now});

  final BudgetStatus status;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final month = Month.of(now);
    final relative = RelativeDate(
      l10n,
      Localizations.localeOf(context).toLanguageTag(),
      now,
    );
    // Jours restants, aujourd'hui compris.
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day + 1;
    final over = status.level == BudgetLevel.exceeded;

    return InkWell(
      onTap: () => context.push(AppRoutes.editBudget(status.budget.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(
            l10n.budgetMonthTitle(relative.month(month)),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.inkSecondary,
            ),
          ),
          Text.rich(
            TextSpan(
              text: '${MoneyFormat.amount(status.spent)} ',
              children: [
                TextSpan(
                  text: l10n.budgetOfLimit(
                    MoneyFormat.amount(status.budget.limit),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.inkSecondary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w600,
              letterSpacing: -1,
            ),
          ),
          BudgetBar(status: status, height: 10),
          Text(
            l10n.budgetDaysLeft(daysLeft),
            style: TextStyle(fontSize: 12.5, color: colors.inkTertiary),
          ),
          Text(
            over
                ? l10n.budgetOverSentence(MoneyFormat.amount(-status.remaining))
                : l10n.budgetRemainingSentence(
                    MoneyFormat.amount(status.remaining),
                    MoneyFormat.amount(
                      dailyAllowance(status.remaining, daysLeft),
                    ),
                  ),
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: over ? colors.negative : colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Alert extends StatelessWidget {
  const _Alert({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.warningSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Icon(AppIcons.info, size: 17, color: colors.warning),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: colors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
