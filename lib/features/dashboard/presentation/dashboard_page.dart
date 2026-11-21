import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/clock.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/money/money.dart';
import '../../../core/time/month.dart';
import '../../../core/widgets/amount_display.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/section_tint.dart';
import '../../../l10n/l10n.dart';
import '../../accounts/domain/accounts_summary.dart';
import '../../accounts/presentation/account_labels.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../assistant/presentation/ai_model_controller.dart';
import '../../assistant/presentation/assistant_controller.dart';
import '../../budgets/presentation/budget_widgets.dart';
import '../../budgets/presentation/budgets_providers.dart';
import '../../categories/presentation/category_icons.dart';
import '../../forecast/domain/forecast.dart';
import '../../forecast/presentation/forecast_chart.dart';
import '../../forecast/presentation/forecast_providers.dart';
import '../../goals/domain/savings_goal.dart';
import '../../goals/presentation/goals_providers.dart';
import '../../planned/presentation/spending_calendar.dart';
import '../../recurring/presentation/recurring_providers.dart';
import '../../settings/presentation/settings_providers.dart';
import '../../transactions/domain/expense_breakdown.dart';
import '../../transactions/domain/transaction_stats.dart';
import '../../transactions/presentation/new_operation_sheet.dart';
import '../../transactions/presentation/transaction_labels.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../domain/home_insight.dart';

/// Tableau de bord.
///
/// Tant qu'il manque un compte ou une première opération : état « premier
/// lancement » (maquette Accueil-Vide) avec les étapes pour bien démarrer.
/// Ensuite : solde, revenus et dépenses du mois, dernières opérations.
/// Budgets, prévisions et « Où va ton argent » viendront avec leurs
/// fonctionnalités.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final accounts = ref.watch(activeAccountsProvider);
    final hasTransactions = ref.watch(hasTransactionsProvider);
    // Évite d'afficher brièvement l'état vide pendant la première lecture.
    if (!accounts.hasValue || !hasTransactions.hasValue) {
      return const Scaffold();
    }
    final summary = AccountsSummary.of(accounts.requireValue);
    final hasAccounts = summary.count > 0;
    final active = hasAccounts && hasTransactions.requireValue;

    return SectionTint(
      color: context.colors.primaryTint,
      child: AddOperationScaffold(
        showButton: hasAccounts,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              12,
              AppSpacing.gutter,
              hasAccounts ? 120 : 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 32,
              children: [
                for (final (i, section) in [
                  _Header(date: now),
                  _Balance(
                    summary: summary,
                    masked: ref.watch(amountsHiddenProvider),
                    onToggleMask: ref
                        .read(amountsHiddenProvider.notifier)
                        .toggle,
                  ),
                  if (active) ...[
                    // Ordre de la maquette : du présent vers l'avenir.
                    _MonthTotals(month: ref.watch(monthOfProvider)(now)),
                    const SpendingCalendar(),
                    const _AccountsStrip(),
                    const _RecentOperations(),
                    const _Budgets(),
                    const _CopilotInsight(),
                    _WhereMoneyGoes(month: ref.watch(monthOfProvider)(now)),
                    const _ForecastCard(),
                  ] else ...[
                    _GetStarted(hasAccounts: hasAccounts),
                    const _CopilotHint(),
                    const _PrivacyNote(),
                  ],
                ].indexed)
                  // Sections en cascade à l'ouverture.
                  FadeSlideIn(index: i, child: section),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Revenus et dépenses du mois (transferts exclus).
class _MonthTotals extends ConsumerWidget {
  const _MonthTotals({required this.month});

  final Month month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final totals = TransactionTotals.of(
      ref.watch(monthTransactionsProvider(month)).value ?? const [],
    );
    final masked = ref.watch(amountsHiddenProvider);
    final relative = RelativeDate(
      l10n,
      Localizations.localeOf(context).toLanguageTag(),
      ref.watch(clockProvider)(),
    );
    Widget cell(
      IconData icon,
      Color iconColor,
      String label,
      Money amount,
      EdgeInsets padding,
    ) => Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Row(
            spacing: 6,
            children: [
              Icon(icon, size: 14, color: iconColor),
              Flexible(
                child: Text(
                  label,
                  style: AppText.label.copyWith(color: colors.inkSecondary),
                ),
              ),
            ],
          ),
          // Entrées en vert, sorties en terracotta (maquette).
          Text(
            masked ? MoneyFormat.masked : MoneyFormat.amount(amount),
            style: AppText.amount(20, inline: true).copyWith(color: iconColor),
          ),
        ],
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: colors.line)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: colors.line)),
                ),
                child: cell(
                  AppIcons.arrowDownLeftBold,
                  colors.positive,
                  l10n.dashboardIncomeOf(relative.month(month)),
                  totals.income,
                  const EdgeInsets.fromLTRB(0, 16, 16, 16),
                ),
              ),
            ),
            Expanded(
              child: cell(
                AppIcons.arrowUpRightBold,
                colors.expense,
                l10n.dashboardExpenseOf(relative.month(month)),
                totals.expense,
                const EdgeInsets.fromLTRB(16, 16, 0, 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// « Où va ton argent » : une seule barre empilée et une légende chiffrée
/// (aucune lecture d'angle). Masquée sans dépense dans le mois.
class _WhereMoneyGoes extends ConsumerWidget {
  const _WhereMoneyGoes({required this.month});

  final Month month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final breakdown = ExpenseBreakdown.of(
      ref.watch(monthTransactionsProvider(month)).value ?? const [],
    );
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final relative = RelativeDate(
      l10n,
      Localizations.localeOf(context).toLanguageTag(),
      ref.watch(clockProvider)(),
    );
    final monthName = [
      RelativeDate.capitalize(relative.month(month)),
      ?relative.monthRange(month),
    ].join(' · ');
    String name(ExpenseShare share) =>
        share.category?.name ?? l10n.accountsOthers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.dashboardWhereMoney,
                  style: AppText.sectionTitle,
                ),
              ),
            ),
            // Mois budgétaire décalé : dates en plus, sur deux lignes si besoin.
            Flexible(
              child: Text(
                monthName,
                textAlign: TextAlign.end,
                style: AppText.label.copyWith(color: colors.inkTertiary),
              ),
            ),
          ],
        ),
        Semantics(
          label: [
            for (final share in breakdown.shares)
              l10n.accountsShare(name(share), share.percent),
          ].join(', '),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              height: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 2,
                children: [
                  for (final (i, share) in breakdown.shares.indexed)
                    if (share.percent > 0)
                      Expanded(
                        flex: share.percent,
                        child: ColoredBox(color: colors.expenseChart[i]),
                      ),
                ],
              ),
            ),
          ),
        ),
        ExcludeSemantics(
          child: Column(
            spacing: 12,
            children: [
              // Trois premières catégories avec leur icône, puis le reste.
              for (final (i, share) in breakdown.shares.take(3).indexed)
                Row(
                  spacing: 10,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors
                            .category(share.category?.iconKey ?? '')
                            .background,
                        border: Border.all(
                          color: colors.expenseChart[i],
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        categoryIcon(share.category?.iconKey ?? ''),
                        size: 14,
                        color: colors
                            .category(share.category?.iconKey ?? '')
                            .ink,
                      ),
                    ),
                    // Nom et part se réduisent au lieu de déborder ; le
                    // montant reste toujours entier.
                    Expanded(
                      child: Row(
                        spacing: 10,
                        children: [
                          Flexible(
                            child: Text(
                              name(share),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body.medium,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              l10n.dashboardShare(share.percent),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body.copyWith(
                                color: colors.inkTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      ref.watch(amountsHiddenProvider)
                          ? MoneyFormat.masked
                          : MoneyFormat.amount(share.amount),
                      style: AppText.body.semibold,
                    ),
                  ],
                ),
              if (breakdown.shares.length > 3)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.dashboardRestLine(
                      ref.watch(amountsHiddenProvider)
                          ? MoneyFormat.masked
                          : MoneyFormat.amount(
                              breakdown.shares
                                  .skip(3)
                                  .fold(Money.zero, (sum, s) => sum + s.amount),
                            ),
                      [
                        for (final share in breakdown.shares.skip(3))
                          name(share),
                      ].join(', '),
                    ),
                    style: AppText.caption.copyWith(color: colors.inkTertiary),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// « À surveiller » : budgets au seuil d'alerte, dépassés ou qui seront
/// dépassés avant la fin du mois (masquée s'il n'y en a pas), et une
/// question au Copilote sur le premier.
class _Budgets extends ConsumerWidget {
  const _Budgets();

  static const _maxRows = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final overview = ref.watch(budgetsOverviewProvider);
    final watched = overview?.watched ?? const [];
    if (overview == null || watched.isEmpty) return const SizedBox.shrink();
    final first = watched.first.budget.category?.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(l10n.budgetWatchTitle, style: AppText.sectionTitle),
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.budgets),
              child: Text(l10n.budgetsTitle),
            ),
          ],
        ),
        for (final status in watched.take(_maxRows))
          BudgetRow(
            status: status,
            overrunOn: overview.overrunOf(status),
            masked: ref.watch(amountsHiddenProvider),
            showAmounts: false,
            onTap: () => context.go(AppRoutes.budgets),
          ),
        if (first != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                ref
                    .read(assistantRequestProvider.notifier)
                    .ask(l10n.dashboardWhyIncrease(first.toLowerCase()));
                context.go(AppRoutes.assistant);
              },
              icon: Icon(AppIcons.chatCircleText, size: 17, color: colors.info),
              label: Text(l10n.dashboardWhyIncrease(first.toLowerCase())),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: colors.ink,
              ),
            ),
          ),
      ],
    );
  }
}

/// « Comptes et épargne » : les comptes actifs puis les objectifs, en
/// cartes qui défilent ; « Tout voir » ouvre Mes comptes.
class _AccountsStrip extends ConsumerWidget {
  const _AccountsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final accounts = ref.watch(activeAccountsProvider).value ?? const [];
    if (accounts.isEmpty) return const SizedBox.shrink();
    final goals = GoalsSummary.of(ref.watch(goalsProvider).value ?? const []);
    final masked = ref.watch(amountsHiddenProvider);
    String amount(Money m) =>
        masked ? MoneyFormat.masked : MoneyFormat.amount(m);

    Widget card({
      required IconData icon,
      required Color background,
      required Color ink,
      required String name,
      required String value,
      required VoidCallback onTap,
    }) => SizedBox(
      width: 128,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: background,
                  ),
                  child: Icon(icon, size: 16, color: ink),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(
                        color: colors.inkSecondary,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value, style: AppText.bodyLarge.semibold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.dashboardAccountsTitle,
                  style: AppText.sectionTitle,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.accounts),
              child: Text(l10n.dashboardSeeAll),
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            spacing: 8,
            children: [
              for (final account in accounts)
                card(
                  icon: account.type.icon,
                  background: colors.primarySoft,
                  ink: colors.onPrimarySoft,
                  name: account.name,
                  value: amount(account.balance),
                  onTap: () => context.go(AppRoutes.accountDetail(account.id)),
                ),
              card(
                icon: AppIcons.target,
                background: colors.warningSoft,
                ink: colors.warning,
                name: l10n.dashboardGoalsCard,
                value: amount(goals.saved),
                onTap: () => context.go(AppRoutes.goals),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentOperations extends ConsumerWidget {
  const _RecentOperations();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final recent = ref.watch(recentTransactionsProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(l10n.dashboardRecent, style: AppText.sectionTitle),
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.transactions),
              child: Text(l10n.dashboardSeeAll),
            ),
          ],
        ),
        for (final t in recent)
          TransactionTile(
            transaction: t,
            masked: ref.watch(amountsHiddenProvider),
            onTap: () => context.push(AppRoutes.transactionDetail(t.id)),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatted = DateFormat('EEEE d MMMM', locale).format(date);
    final capitalized = formatted[0].toUpperCase() + formatted.substring(1);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(context.l10n.dashboardWelcome, style: AppText.subtitle),
              Text(
                capitalized,
                style: AppText.label.copyWith(color: colors.inkTertiary),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: context.l10n.settingsTitle,
          onPressed: () => context.push(AppRoutes.settings),
          icon: const Icon(AppIcons.gearSix, size: 20),
          style: IconButton.styleFrom(
            fixedSize: const Size.square(44),
            backgroundColor: colors.primarySoft,
            foregroundColor: colors.onPrimarySoft,
          ),
        ),
      ],
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({
    required this.summary,
    required this.masked,
    required this.onToggleMask,
  });

  final AccountsSummary summary;

  /// Montants de l'accueil masqués ; l'œil les affiche ou les masque.
  final bool masked;
  final VoidCallback onToggleMask;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final hasAccounts = summary.count > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                l10n.dashboardBalanceCount(summary.count),
                style: AppText.body.medium.copyWith(color: colors.inkSecondary),
              ),
            ),
            if (hasAccounts)
              IconButton(
                tooltip: masked
                    ? l10n.dashboardShowAmounts
                    : l10n.dashboardHideAmounts,
                onPressed: onToggleMask,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  masked ? AppIcons.eye : AppIcons.eyeSlash,
                  size: 18,
                  color: colors.inkSecondary,
                ),
              ),
          ],
        ),
        // Masquer : fondu et flou ; à l'ouverture, le solde compte de 92 à
        // 100 %.
        BlurFadeSwitcher(
          child: KeyedSubtree(
            key: ValueKey(masked && hasAccounts),
            child: CountingValue(
              value: summary.total.value,
              builder: (context, value) => AmountDisplay(
                masked: masked && hasAccounts,
                amount: Money(value),
                fontSize: 46,
                // Sans compte, le 0 reste discret : ce n'est pas un vrai
                // solde. Sinon, forêt (maquette).
                color: hasAccounts ? colors.primary : colors.inkTertiary,
                currencyColor: hasAccounts
                    ? colors.inkSecondary
                    : colors.inkTertiary,
              ),
            ),
          ),
        ),
        // Les comptes sont détaillés dans « Comptes et épargne ».
        if (!hasAccounts)
          Text(
            l10n.dashboardEmptyBalanceHint,
            style: AppText.bodySmall.copyWith(color: colors.inkSecondary),
          ),
      ],
    );
  }
}

class _GetStarted extends StatelessWidget {
  const _GetStarted({required this.hasAccounts});

  final bool hasAccounts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Semantics(
            header: true,
            child: Text(
              l10n.dashboardGetStartedTitle,
              style: AppText.sectionTitle,
            ),
          ),
        ),
        _StepRow(
          number: 1,
          title: l10n.dashboardStepAccountsTitle,
          subtitle: l10n.dashboardStepAccountsSubtitle,
          done: hasAccounts,
          isNext: !hasAccounts,
          onTap: () => hasAccounts
              ? context.go(AppRoutes.accounts)
              : context.push(AppRoutes.newAccount),
        ),
        _StepRow(
          number: 2,
          title: l10n.dashboardStepTransactionsTitle,
          subtitle: l10n.dashboardStepTransactionsSubtitle,
          isNext: hasAccounts,
          onTap: hasAccounts ? () => openNewOperation(context) : null,
        ),
        _StepRow(
          number: 3,
          title: l10n.dashboardStepBudgetTitle,
          subtitle: l10n.dashboardStepBudgetSubtitle,
          showDivider: false,
        ),
      ],
    );
  }
}

/// Étape de démarrage. Cliquable seulement si son écran existe ([onTap]).
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.title,
    required this.subtitle,
    this.done = false,
    this.isNext = false,
    this.showDivider = true,
    this.onTap,
  });

  final int number;
  final String title;
  final String subtitle;
  final bool done;

  /// Prochaine étape à faire : pastille mise en avant.
  final bool isNext;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color badgeColor;
    final Color badgeInk;
    if (done) {
      (badgeColor, badgeInk) = (colors.primarySoft, colors.onPrimarySoft);
    } else if (isNext) {
      (badgeColor, badgeInk) = (colors.primary, colors.onPrimary);
    } else {
      (badgeColor, badgeInk) = (colors.chip, colors.inkSecondary);
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: showDivider
            ? BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.line)),
              )
            : null,
        child: Row(
          spacing: 14,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor,
              ),
              child: done
                  ? Icon(AppIcons.checkBold, size: 16, color: badgeInk)
                  : Text(
                      '$number',
                      style: AppText.body.bold.copyWith(color: badgeInk),
                    ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(title, style: AppText.bodyLarge.semibold),
                  Text(
                    subtitle,
                    style: AppText.caption.copyWith(color: colors.inkTertiary),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.caretRight, size: 16, color: colors.inkTertiary),
          ],
        ),
      ),
    );
  }
}

class _CopilotHint extends StatelessWidget {
  const _CopilotHint();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: colors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primarySoft,
            ),
            child: Icon(
              AppIcons.chatCircleText,
              size: 17,
              color: colors.onPrimarySoft,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(l10n.dashboardCopilotHint, style: AppText.bodyLarge.prose),
                TextButton(
                  onPressed: () => context.go(AppRoutes.assistant),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 44),
                  ),
                  child: Text(l10n.dashboardCopilotAction),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = AppText.label.prose.copyWith(color: colors.inkTertiary);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(AppIcons.lockSimple, size: 15, color: colors.inkTertiary),
        ),
        Expanded(child: Text(context.l10n.dashboardPrivacyNote, style: style)),
      ],
    );
  }
}

/// Suggestion du Copilote (maquette Accueil) : phrase factuelle calculée par
/// l'application, puis « Demander au Copilote ».
class _CopilotInsight extends ConsumerWidget {
  const _CopilotInsight();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Coupées dans les Paramètres, ou montants masqués : la phrase en cite.
    if (!ref.watch(suggestionsSettingProvider) ||
        ref.watch(amountsHiddenProvider)) {
      return const SizedBox.shrink();
    }
    final colors = context.colors;
    final l10n = context.l10n;
    final now = ref.watch(clockProvider)();
    final month = ref.watch(monthOfProvider)(now);
    final history = ref.watch(spendingHistoryProvider).value;
    final insight = HomeInsights.pick(
      budgets: ref.watch(budgetsOverviewProvider),
      forecast:
          history != null &&
              history.daysOfHistory(now) >= Forecast.minHistoryDays
          ? ref.watch(forecastProvider(ForecastHorizon.month))
          : null,
      pending: ref.watch(pendingOccurrencesProvider),
      currentMonth:
          ref.watch(monthTransactionsProvider(month)).value ?? const [],
      previousMonth:
          ref.watch(monthTransactionsProvider(month.previous)).value ??
          const [],
      month: month,
      now: now,
      l10n: l10n,
    );
    if (insight == null) return const SizedBox.shrink();
    final question = insight.question;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Icon(
                AppIcons.chatCircleText,
                size: 18,
                color: colors.onPrimarySoft,
              ),
              Expanded(
                child: Text(
                  insight.text,
                  style: AppText.bodyLarge.prose.copyWith(
                    color: colors.onPrimarySoft,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                if (question == null) {
                  context.go(AppRoutes.recurring);
                  return;
                }
                // Question posée seulement si l'assistant est prêt.
                if (ref.read(aiModelControllerProvider).status ==
                    AiModelStatus.ready) {
                  ref.read(assistantRequestProvider.notifier).ask(question);
                }
                context.go(AppRoutes.assistant);
              },
              child: Text(
                question == null ? l10n.inSeePending : l10n.inAskCopilot,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// « Dans 30 jours » (maquette Accueil) : solde prévu, fourchette, courbe.
class _ForecastCard extends ConsumerWidget {
  const _ForecastCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final now = ref.watch(clockProvider)();
    final history = ref.watch(spendingHistoryProvider).value;
    if (history == null ||
        history.daysOfHistory(now) < Forecast.minHistoryDays) {
      return const SizedBox.shrink();
    }
    final forecast = ref.watch(forecastProvider(ForecastHorizon.month));
    if (forecast == null) return const SizedBox.shrink();
    final masked = ref.watch(amountsHiddenProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final (low, high) = forecast.endRange;
    String amount(Money m) => masked
        ? MoneyFormat.masked
        : m.isNegative
        ? MoneyFormat.signed(m)
        : MoneyFormat.amount(m);
    final level = switch (forecast.reliability) {
      ForecastReliability.high => l10n.forecastReliabilityHigh,
      ForecastReliability.medium => l10n.forecastReliabilityMedium,
      ForecastReliability.low => l10n.forecastReliabilityLow,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.homeForecastTitle,
                  style: AppText.sectionTitle,
                ),
              ),
            ),
            Flexible(
              child: Text(
                RelativeDate.capitalize(l10n.forecastReliability(level)),
                textAlign: TextAlign.end,
                style: AppText.label.copyWith(color: colors.inkTertiary),
              ),
            ),
          ],
        ),
        Text(
          '≈ ${amount(forecast.endBalance)} ${l10n.currencyLabel}',
          style: AppText.amount(24, inline: true),
        ),
        Text(
          l10n.homeForecastRange(amount(low), amount(high)),
          style: AppText.label.copyWith(color: colors.inkSecondary),
        ),
        if (!masked)
          ForecastChart(
            forecast: forecast,
            height: 110,
            semanticLabel: l10n.forecastChartLabel(
              AppDateFormat.dayMonth(forecast.endDate, locale),
              MoneyFormat.amount(forecast.endBalance),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.go(AppRoutes.forecast),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 44),
            ),
            child: Text(l10n.homeForecastLink),
          ),
        ),
      ],
    );
  }
}
