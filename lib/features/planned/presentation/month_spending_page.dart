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
import '../../categories/presentation/category_icons.dart';
import '../../settings/presentation/settings_providers.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../domain/month_spending.dart';
import '../domain/planned_expense.dart';
import 'planned_labels.dart';
import 'planned_providers.dart';
import 'spending_calendar.dart';

/// « Dépenses du mois » (maquette Depenses-Mois) : total prévu, en retard,
/// à payer, payées par catégorie ; mois précédent et suivant.
class MonthSpendingPage extends ConsumerStatefulWidget {
  const MonthSpendingPage({required this.year, required this.month, super.key});

  final int year;
  final int month;

  @override
  ConsumerState<MonthSpendingPage> createState() => _MonthSpendingPageState();
}

class _MonthSpendingPageState extends ConsumerState<MonthSpendingPage> {
  /// (année, mois) affichés ; le jour de début vient du réglage.
  late (int, int) _shown = (widget.year, widget.month);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final now = ref.watch(clockProvider)();
    final relative = RelativeDate(
      l10n,
      Localizations.localeOf(context).toLanguageTag(),
      now,
    );
    final month = Month(
      _shown.$1,
      _shown.$2,
      startDay: ref.watch(budgetMonthStartProvider),
    );
    final (first, last) = ref.watch(spendingMonthsProvider);
    final spending = ref.watch(monthSpendingProvider(month));
    final masked = ref.watch(amountsHiddenProvider);
    String amount(Money value) =>
        masked ? MoneyFormat.masked : MoneyFormat.amount(value);
    void go(Month target) =>
        setState(() => _shown = (target.year, target.month));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.monthPageTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: l10n.calPrevMonth,
                  onPressed: month.compareTo(first) > 0
                      ? () => go(month.previous)
                      : null,
                  icon: const Icon(AppIcons.caretLeftBold, size: 16),
                ),
                Expanded(
                  child: Text(
                    spendingMonthLabel(relative, month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.calNextMonth,
                  onPressed: month.compareTo(last) < 0
                      ? () => go(month.next)
                      : null,
                  icon: const Icon(AppIcons.caretRightBold, size: 16),
                ),
              ],
            ),
            if (spending != null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.monthTotalLabel,
                style: TextStyle(fontSize: 13, color: colors.inkSecondary),
              ),
              Text.rich(
                TextSpan(
                  text: '${amount(spending.total)} ',
                  children: [
                    TextSpan(
                      text: l10n.currencyLabel,
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.inkSecondary,
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
              const SizedBox(height: 12),
              MonthSpendingSummary(
                spending: spending,
                now: now,
                masked: masked,
                showTitle: false,
              ),
              if (spending.isEmpty)
                _Empty(month: relative.month(month))
              else ...[
                ..._dueSection(
                  context,
                  l10n.monthLateTitle,
                  [
                    for (final d in spending.dues)
                      if (d.statusOn(now) == PlannedStatus.late) d,
                  ],
                  now,
                  relative,
                  masked,
                ),
                ..._dueSection(
                  context,
                  l10n.monthPlanTitle,
                  [
                    for (final d in spending.dues)
                      if (d.statusOn(now) == PlannedStatus.planned) d,
                  ],
                  now,
                  relative,
                  masked,
                ),
                if (spending.paidByCategory.isNotEmpty) ...[
                  _SectionTitle(l10n.monthPaidTitle(amount(spending.paid))),
                  for (final (category, sum) in spending.paidByCategory)
                    _CategoryBar(
                      name: category.name,
                      icon: categoryIcon(category.iconKey),
                      amount: masked
                          ? MoneyFormat.masked
                          : MoneyFormat.signed(-sum),
                      ratio: sum.value / spending.paidByCategory.first.$2.value,
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        ref
                            .read(transactionsMonthRequestProvider.notifier)
                            .request(month);
                        context.go(AppRoutes.transactions);
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(l10n.monthSeeOperations),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              Text(
                l10n.monthRule,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: colors.inkTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _dueSection(
    BuildContext context,
    String Function(String amount) title,
    List<DueItem> dues,
    DateTime now,
    RelativeDate relative,
    bool masked,
  ) {
    if (dues.isEmpty) return const [];
    final total = dues.fold(Money.zero, (sum, d) => sum + d.amount);
    return [
      _SectionTitle(
        title(masked ? MoneyFormat.masked : MoneyFormat.amount(total)),
      ),
      for (final d in dues)
        DueRow(
          due: d,
          now: now,
          masked: masked,
          meta: dueMeta(context.l10n, relative, d, now),
        ),
    ];
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 4),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.name,
    required this.icon,
    required this.amount,
    required this.ratio,
  });

  final String name;
  final IconData icon;
  final String amount;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
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
              spacing: 6,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      amount,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                ExcludeSemantics(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0, 1),
                      minHeight: 5,
                      color: colors.chart.first,
                      backgroundColor: colors.chip,
                    ),
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

class _Empty extends StatelessWidget {
  const _Empty({required this.month});

  final String month;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        spacing: 6,
        children: [
          Text(
            l10n.monthEmptyTitle(month),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            l10n.monthEmptyText,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: colors.inkSecondary),
          ),
        ],
      ),
    );
  }
}
