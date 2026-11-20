import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/clock.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/money/money.dart';
import '../../../core/time/month.dart';
import '../../../core/widgets/amount_display.dart';
import '../../../l10n/l10n.dart';
import '../../accounts/domain/accounts_summary.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../assistant/presentation/ai_model_controller.dart';
import '../../assistant/presentation/assistant_controller.dart';
import '../../budgets/presentation/budget_widgets.dart';
import '../../budgets/presentation/budgets_providers.dart';
import '../../forecast/domain/forecast.dart';
import '../../forecast/presentation/forecast_chart.dart';
import '../../forecast/presentation/forecast_providers.dart';
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

    return Scaffold(
      floatingActionButton: hasAccounts ? const AddOperationButton() : null,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 12, 24, hasAccounts ? 120 : 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 32,
            children: [
              _Header(date: now),
              _Balance(
                summary: summary,
                masked: ref.watch(amountsHiddenProvider),
                onToggleMask: ref.read(amountsHiddenProvider.notifier).toggle,
              ),
              if (active) ...[
                _MonthTotals(month: ref.watch(monthOfProvider)(now)),
                const SpendingCalendar(),
                _WhereMoneyGoes(month: ref.watch(monthOfProvider)(now)),
                const _CopilotInsight(),
                const _Budgets(),
                const _ForecastCard(),
                const _RecentOperations(),
              ] else ...[
                _GetStarted(hasAccounts: hasAccounts),
                const _CopilotHint(),
                const _PrivacyNote(),
              ],
            ],
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
                  style: TextStyle(fontSize: 13, color: colors.inkSecondary),
                ),
              ),
            ],
          ),
          Text(
            masked ? MoneyFormat.masked : MoneyFormat.amount(amount),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
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
                  l10n.dashboardMonthIncome,
                  totals.income,
                  const EdgeInsets.fromLTRB(0, 16, 16, 16),
                ),
              ),
            ),
            Expanded(
              child: cell(
                AppIcons.arrowUpRightBold,
                colors.inkSecondary,
                l10n.dashboardMonthExpense,
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
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Mois budgétaire décalé : dates en plus, sur deux lignes si besoin.
            Flexible(
              child: Text(
                monthName,
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 13, color: colors.inkTertiary),
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
            borderRadius: BorderRadius.circular(6),
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
                        child: ColoredBox(color: colors.chart[i]),
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
              for (final (i, share) in breakdown.shares.indexed)
                Row(
                  spacing: 10,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.chart[i],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const SizedBox.square(dimension: 10),
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              l10n.dashboardShare(share.percent),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Section « Budgets » : les budgets par catégorie du mois (masquée sans
/// budget).
class _Budgets extends ConsumerWidget {
  const _Budgets();

  static const _maxRows = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final budgets = ref.watch(budgetsOverviewProvider)?.categories ?? const [];
    if (budgets.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.budgetsTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.budgets),
              child: Text(l10n.dashboardSeeAll),
            ),
          ],
        ),
        for (final status in budgets.take(_maxRows))
          BudgetRow(
            status: status,
            masked: ref.watch(amountsHiddenProvider),
            showAmounts: false,
            onTap: () => context.go(AppRoutes.budgets),
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
                child: Text(
                  l10n.dashboardRecent,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
              Text(
                context.l10n.dashboardWelcome,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                capitalized,
                style: TextStyle(fontSize: 13, color: colors.inkTertiary),
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
                l10n.dashboardTotalBalance,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.inkSecondary,
                ),
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
        AmountDisplay(
          masked: masked && hasAccounts,
          amount: summary.total,
          fontSize: 46,
          // Sans compte, le 0 reste discret : ce n'est pas un vrai solde.
          color: hasAccounts ? colors.ink : colors.inkTertiary,
          currencyColor: hasAccounts ? colors.inkSecondary : colors.inkTertiary,
        ),
        if (hasAccounts)
          TextButton(
            onPressed: () => context.go(AppRoutes.accounts),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 44),
              alignment: Alignment.centerLeft,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Flexible(
                  child: Text(l10n.dashboardAccountsLink(summary.count)),
                ),
                const Icon(AppIcons.caretRight, size: 12),
              ],
            ),
          )
        else
          Text(
            l10n.dashboardEmptyBalanceHint,
            style: TextStyle(fontSize: 13.5, color: colors.inkSecondary),
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
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
          onTap: hasAccounts ? () => showNewOperationSheet(context) : null,
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: badgeInk,
                      ),
                    ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12.5, color: colors.inkTertiary),
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
                Text(
                  l10n.dashboardCopilotHint,
                  style: const TextStyle(fontSize: 14.5, height: 1.5),
                ),
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
    final style = TextStyle(
      fontSize: 13,
      height: 1.5,
      color: colors.inkTertiary,
    );
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
        borderRadius: BorderRadius.circular(16),
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
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.4,
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
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Flexible(
              child: Text(
                RelativeDate.capitalize(l10n.forecastReliability(level)),
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 13, color: colors.inkTertiary),
              ),
            ),
          ],
        ),
        Text(
          '≈ ${amount(forecast.endBalance)} ${l10n.currencyLabel}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
        Text(
          l10n.homeForecastRange(amount(low), amount(high)),
          style: TextStyle(fontSize: 13, color: colors.inkSecondary),
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
