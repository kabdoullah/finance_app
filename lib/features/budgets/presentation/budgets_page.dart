import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/clock.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/money/money.dart';
import '../../../core/time/month.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/section_tint.dart';
import '../../../l10n/l10n.dart';
import '../../assistant/presentation/assistant_controller.dart';
import '../../goals/presentation/budgets_goals_switch.dart';
import '../../transactions/presentation/transactions_providers.dart';
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

    return SectionTint(
      color: context.colors.primaryTint,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            children: [
              Semantics(
                header: true,
                child: Text(l10n.budgetsTitle, style: AppText.screenTitle),
              ),
              const SizedBox(height: 16),
              const BudgetsGoalsSwitch(showGoals: false),
              const SizedBox(height: 24),
              if (overview != null) ...[
                if (overview.global case final global?)
                  _MonthBudget(
                    status: global,
                    now: now,
                    month: overview.month,
                    overrunOn: overview.overrunOf(global),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.newBudget),
                    icon: const Icon(AppIcons.plusBold, size: 16),
                    label: Text(l10n.budgetNoGlobal),
                  ),
                for (final status in overview.exceeded)
                  if (status.budget.category case final category?)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _Alert(
                        icon: AppIcons.warningCircleBold,
                        background: colors.negativeSoft,
                        foreground: colors.negative,
                        title: l10n.budgetExceededAlert(
                          category.name,
                          MoneyFormat.amount(-status.remaining),
                        ),
                        body: switch (overview.driverOf(status)) {
                          final driver? => l10n.budgetDriver(
                            driver.category.name,
                            driver.count,
                            MoneyFormat.amount(driver.total),
                          ),
                          null => null,
                        },
                        linkLabel: l10n.budgetSeeOperations,
                        onLink: () =>
                            _showOperations(context, ref, category.id),
                      ),
                    ),
                const SizedBox(height: 28),
                if (overview.categories.isEmpty && overview.global == null)
                  Text(
                    l10n.budgetEmpty,
                    style: AppText.body.prose.copyWith(
                      color: colors.inkSecondary,
                    ),
                  ),
                // Maquette : « À surveiller » puis « Dans les clous ».
                for (final (title, list, isWatch) in [
                  (l10n.budgetWatchTitle, overview.watched, true),
                  (l10n.budgetCalmTitle, overview.calm, false),
                ])
                  if (list.isNotEmpty) ...[
                    _SectionHeader(
                      title: title,
                      trailing: l10n.budgetCategoryCount(list.length),
                    ),
                    for (final (i, status) in list.indexed)
                      FadeSlideIn(
                        index: i,
                        child: BudgetRow(
                          status: status,
                          overrunOn: overview.overrunOf(status),
                          onTap: () => context.push(
                            AppRoutes.editBudget(status.budget.id),
                          ),
                        ),
                      ),
                    if (isWatch)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            ref
                                .read(assistantRequestProvider.notifier)
                                .ask(
                                  l10n.budgetHowToFixQuestion(
                                    list.first.budget.category?.name ??
                                        l10n.budgetAllExpenses,
                                  ),
                                );
                            context.go(AppRoutes.assistant);
                          },
                          icon: Icon(
                            AppIcons.chatCircleText,
                            size: 17,
                            color: colors.info,
                          ),
                          label: Text(l10n.budgetHowToFix),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: colors.ink,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                if (overview.withoutBudget.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.budgetWithout(
                      overview.withoutBudget.map((c) => c.name).join(', '),
                    ),
                    style: AppText.caption.prose.copyWith(
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Ouvre l'onglet Transactions filtré sur [categoryId], mois en cours.
void _showOperations(BuildContext context, WidgetRef ref, String categoryId) {
  ref.read(transactionsCategoryRequestProvider.notifier).request(categoryId);
  context.go(AppRoutes.transactions);
}

/// « Budget de novembre » : dépensé / limite, barre, reste par jour.
class _MonthBudget extends StatelessWidget {
  const _MonthBudget({
    required this.status,
    required this.now,
    required this.month,
    this.overrunOn,
  });

  final BudgetStatus status;
  final DateTime now;
  final Month month;

  /// Dépassement prévu du budget global au rythme actuel.
  final DateTime? overrunOn;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final relative = RelativeDate(
      l10n,
      Localizations.localeOf(context).toLanguageTag(),
      now,
    );
    final locale = Localizations.localeOf(context).toLanguageTag();
    // Jours restants, aujourd'hui compris.
    final daysLeft = month.daysLeft(now);
    final range = relative.monthRange(month);
    final small = AppText.small.copyWith(color: colors.inkTertiary);
    final over = status.level == BudgetLevel.exceeded;

    return InkWell(
      onTap: () => context.push(AppRoutes.editBudget(status.budget.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          DefaultTextStyle.merge(
            style: AppText.bodySmall.medium.copyWith(
              color: colors.inkSecondary,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      l10n.budgetMonthTitle(relative.month(month)),
                      ?range,
                    ].join(' · '),
                  ),
                ),
                Text(l10n.budgetDaysLeft(daysLeft)),
              ],
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
                  style: AppText.bodyLarge.semibold.copyWith(
                    letterSpacing: 0,
                    color: colors.inkSecondary,
                  ),
                ),
              ],
            ),
            style: AppText.amount(38, inline: true),
          ),
          _TodayMarker(
            fraction: month.dayOf(now) / month.length,
            child: BudgetBar(status: status, height: 10),
          ),
          Row(
            children: [
              Text(AppDateFormat.dayMonth(month.start, locale), style: small),
              Expanded(
                child: Text(
                  l10n.budgetTodayPace(
                    '${month.dayOf(now) * 100 ~/ month.length}',
                  ),
                  textAlign: TextAlign.center,
                  style: small.copyWith(
                    color: colors.inkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                AppDateFormat.dayMonth(
                  month.end.subtract(const Duration(days: 1)),
                  locale,
                ),
                style: small,
              ),
            ],
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
            style: AppText.body.prose.copyWith(
              color: over ? colors.negative : colors.ink,
            ),
          ),
          if (overrunOn case final date? when !over)
            Text(
              AppDateFormat.sentence(
                l10n.budgetOverrunOn(AppDateFormat.dayMonth(date, locale)),
              ),
              style: AppText.bodySmall.semibold.copyWith(color: colors.warning),
            ),
        ],
      ),
    );
  }
}

/// Trait vertical à la position d'aujourd'hui sur la barre du mois.
class _TodayMarker extends StatelessWidget {
  const _TodayMarker({required this.fraction, required this.child});

  final double fraction;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(padding: const EdgeInsets.only(top: 4), child: child),
        Positioned(
          left: (constraints.maxWidth * fraction - 1).clamp(
            0,
            constraints.maxWidth - 2,
          ),
          top: 0,
          width: 2,
          height: 18,
          child: ColoredBox(color: context.colors.ink),
        ),
      ],
    ),
  );
}

/// Encadré d'alerte des maquettes : icône, titre en gras, explication et
/// lien facultatifs.
class _Alert extends StatelessWidget {
  const _Alert({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    this.body,
    this.linkLabel,
    this.onLink,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final String? body;
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final style = AppText.bodySmall.prose.copyWith(color: foreground);
    final link = linkLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 17, color: foreground),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (body case final body?) TextSpan(text: ' $body'),
                    ],
                  ),
                  style: style,
                ),
                if (link != null)
                  InkWell(
                    onTap: onLink,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        link,
                        style: style.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: foreground,
                        ),
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

/// Titre de section avec un compte à droite (« À surveiller · 2 catégories »).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: AppText.sectionTitle),
          ),
        ),
        Text(
          trailing,
          style: AppText.label.copyWith(color: context.colors.inkTertiary),
        ),
      ],
    ),
  );
}
