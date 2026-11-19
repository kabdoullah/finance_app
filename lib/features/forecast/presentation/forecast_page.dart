import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/clock.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/segmented_choice.dart';
import '../../../l10n/l10n.dart';
import '../../budgets/domain/budget.dart';
import '../../budgets/presentation/budgets_providers.dart';
import '../domain/forecast.dart';
import 'forecast_chart.dart';
import 'forecast_providers.dart';

/// Onglet Prévisions (maquette Previsions) : solde estimé à 7, 30 ou
/// 90 jours, calculé par le moteur déterministe.
class ForecastPage extends ConsumerStatefulWidget {
  const ForecastPage({super.key});

  @override
  ConsumerState<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends ConsumerState<ForecastPage> {
  ForecastHorizon _horizon = ForecastHorizon.month;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final history = ref.watch(spendingHistoryProvider).value;
    final forecast = ref.watch(forecastProvider(_horizon));
    final now = ref.watch(clockProvider)();
    final days = history?.daysOfHistory(now) ?? 0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.forecastTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (history != null && days < Forecast.minHistoryDays)
              _Insufficient(days: days)
            else if (forecast != null) ...[
              SegmentedChoice<ForecastHorizon>(
                options: [
                  (ForecastHorizon.week, l10n.forecastHorizon7),
                  (ForecastHorizon.month, l10n.forecastHorizon30),
                  (ForecastHorizon.quarter, l10n.forecastHorizon90),
                ],
                selected: _horizon,
                onChanged: (h) => setState(() => _horizon = h),
              ),
              const SizedBox(height: 24),
              _Summary(forecast: forecast),
              const SizedBox(height: 20),
              _ChartBlock(forecast: forecast),
              const SizedBox(height: 28),
              _Risks(forecast: forecast),
              const SizedBox(height: 28),
              _Expected(forecast: forecast),
              const SizedBox(height: 24),
              _HowItWorks(forecast: forecast),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.simulation),
                icon: const Icon(AppIcons.target, size: 18),
                label: Text(l10n.forecastSimulate),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.forecastSimulateExample,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.colors.inkTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _day(BuildContext context, DateTime date) => AppDateFormat.dayMonth(
  date,
  Localizations.localeOf(context).toLanguageTag(),
);

/// Montant avec signe moins s'il est négatif (« −12 000 »), sans « + ».
String _amount(Money money) =>
    money.isNegative ? MoneyFormat.signed(money) : MoneyFormat.amount(money);

/// « Pas encore assez de données » : progression vers 14 jours et conseils.
class _Insufficient extends StatelessWidget {
  const _Insufficient({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    const total = Forecast.minHistoryDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        const SizedBox(height: 8),
        Text(
          l10n.forecastInsufficientTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        Text(
          l10n.forecastInsufficientBody,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: colors.inkSecondary,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: days / total,
            minHeight: 8,
            color: colors.primary,
            backgroundColor: colors.chip,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.forecastInsufficientProgress(days, total),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              l10n.forecastInsufficientLeft(total - days),
              style: TextStyle(fontSize: 13, color: colors.inkSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final tip in [
          l10n.forecastTipDaily,
          l10n.forecastTipIncome,
          l10n.forecastTipFixed,
        ])
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Icon(AppIcons.checkBold, size: 15, color: colors.primary),
              Expanded(
                child: Text(
                  tip,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: colors.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.newTransaction()),
          icon: const Icon(AppIcons.plusBold, size: 18),
          label: Text(l10n.forecastAddOperation),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.forecast});

  final Forecast forecast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final (low, high) = forecast.endRange;
    final level = switch (forecast.reliability) {
      ForecastReliability.high => l10n.forecastReliabilityHigh,
      ForecastReliability.medium => l10n.forecastReliabilityMedium,
      ForecastReliability.low => l10n.forecastReliabilityLow,
    };
    Widget cell(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 3,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: colors.inkSecondary)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          spacing: 16,
          children: [
            Expanded(
              child: cell(l10n.forecastCurrent, _amount(forecast.balance)),
            ),
            Expanded(
              child: cell(
                l10n.forecastExpectedOn(_day(context, forecast.endDate)),
                '≈ ${_amount(forecast.endBalance)}',
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.forecastRange(_amount(low), _amount(high)),
                style: TextStyle(fontSize: 13, color: colors.inkSecondary),
              ),
            ),
            _ReliabilityBars(level: forecast.reliability),
            const SizedBox(width: 6),
            Text(
              l10n.forecastReliability(level),
              style: TextStyle(fontSize: 13, color: colors.inkSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReliabilityBars extends StatelessWidget {
  const _ReliabilityBars({required this.level});

  final ForecastReliability level;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 2,
        children: [
          for (var i = 1; i <= 3; i++)
            Container(
              width: 4,
              height: 4.0 + i * 3,
              decoration: BoxDecoration(
                color: i <= level.index + 1 ? colors.primary : colors.line,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartBlock extends StatelessWidget {
  const _ChartBlock({required this.forecast});

  final Forecast forecast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final back = forecast.history.length - 1;
    final start = DateTime(
      forecast.today.year,
      forecast.today.month,
      forecast.today.day - back,
    );
    final todayFraction = back / (back + forecast.horizon.days);
    final small = TextStyle(fontSize: 11.5, color: colors.inkTertiary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        ForecastChart(
          forecast: forecast,
          semanticLabel: l10n.forecastChartLabel(
            _day(context, forecast.endDate),
            _amount(forecast.endBalance),
          ),
        ),
        SizedBox(
          height: 16,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final todayX = constraints.maxWidth * todayFraction;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    child: Text(_day(context, start), style: small),
                  ),
                  Positioned(
                    left: todayX - 40,
                    width: 80,
                    child: Text(
                      l10n.forecastToday,
                      textAlign: TextAlign.center,
                      style: small.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Text(_day(context, forecast.endDate), style: small),
                  ),
                ],
              );
            },
          ),
        ),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _Legend(
              swatch: Container(width: 14, height: 2, color: colors.ink),
              label: l10n.forecastLegendPast,
            ),
            _Legend(
              swatch: Row(
                spacing: 2,
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(width: 4, height: 2, color: colors.primary),
                ],
              ),
              label: l10n.forecastLegendEstimate,
            ),
            _Legend(
              swatch: Container(
                width: 14,
                height: 10,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              label: l10n.forecastLegendRange,
            ),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.swatch, required this.label});

  final Widget swatch;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 6,
    children: [
      swatch,
      Text(
        label,
        style: TextStyle(fontSize: 12, color: context.colors.inkSecondary),
      ),
    ],
  );
}

/// « Risques détectés » : solde négatif, solde bas, budgets dépassés.
class _Risks extends ConsumerWidget {
  const _Risks({required this.forecast});

  final Forecast forecast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final now = ref.watch(clockProvider)();
    final overview = ref.watch(budgetsOverviewProvider);
    final budgets = [
      for (final (status, date)
          in overview?.forecasts ?? const <(BudgetStatus, DateTime)>[])
        if (!date.isAfter(forecast.endDate) && status.budget.category != null)
          (status, date),
    ];
    final negative = forecast.negativeOn;
    final low = forecast.lowBalance;
    final count =
        (negative == null ? 0 : 1) + (low == null ? 0 : 1) + budgets.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                l10n.forecastRisks,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (count > 0)
              Text(
                l10n.forecastRiskCount(count),
                style: TextStyle(fontSize: 13, color: colors.inkTertiary),
              ),
          ],
        ),
        if (negative == null)
          _RiskBox(
            icon: AppIcons.checkCircleBold,
            background: colors.primarySoft,
            foreground: colors.onPrimarySoft,
            body: AppDateFormat.sentence(
              l10n.forecastNoNegative(_day(context, forecast.endDate)),
            ),
          )
        else
          _RiskBox(
            icon: AppIcons.warningCircleBold,
            background: colors.negativeSoft,
            foreground: colors.negative,
            title: AppDateFormat.sentence(
              l10n.forecastNegative(_day(context, negative)),
            ),
            body: l10n.forecastNegativeAdvice,
          ),
        if (low != null)
          _RiskBox(
            icon: AppIcons.warningCircleBold,
            background: colors.warningSoft,
            foreground: colors.warning,
            title: l10n.forecastLow(
              _day(context, low.date),
              MoneyFormat.amount(
                Money((low.balance.value / 1000).round() * 1000),
              ),
            ),
            body: low.beforeIncome
                ? l10n.forecastLowBeforeIncome
                : l10n.forecastLowAdvice,
          ),
        for (final (status, date) in budgets)
          _RiskBox(
            icon: AppIcons.chartDonut,
            background: colors.warningSoft,
            foreground: colors.warning,
            title: l10n.forecastBudget(
              status.budget.category!.name,
              _day(context, date),
            ),
            body: l10n.forecastBudgetPace(
              MoneyFormat.amount(
                Money(status.spent.value ~/ overview!.month.dayOf(now)),
              ),
            ),
            linkLabel: l10n.forecastSeeBudget,
            onLink: () => context.go(AppRoutes.budgets),
          ),
      ],
    );
  }
}

class _RiskBox extends StatelessWidget {
  const _RiskBox({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.body,
    this.title,
    this.linkLabel,
    this.onLink,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String? title;
  final String body;
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 13.5, height: 1.45, color: foreground);
    final link = linkLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
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
                      if (title case final t?)
                        TextSpan(
                          text: '$t ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      TextSpan(text: body),
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

/// « Ce qui est attendu » : totaux, récurrentes datées, dépenses variables.
class _Expected extends StatelessWidget {
  const _Expected({required this.forecast});

  static const _maxEvents = 7;

  final Forecast forecast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    Widget cell(String label, String value, Color color, EdgeInsets padding) =>
        Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 3,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12.5, color: colors.inkSecondary),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        );
    final dateStyle = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: colors.inkTertiary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.forecastExpected,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.recurring),
              child: Text(l10n.forecastRecurring),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: colors.line),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: cell(
                    l10n.forecastExpectedIncome,
                    MoneyFormat.signed(forecast.expectedIncome),
                    colors.positive,
                    const EdgeInsets.fromLTRB(0, 12, 12, 12),
                  ),
                ),
                VerticalDivider(width: 1, color: colors.line),
                Expanded(
                  child: cell(
                    l10n.forecastExpectedExpenses,
                    MoneyFormat.signed(Money(-forecast.expectedExpenses.value)),
                    colors.ink,
                    const EdgeInsets.fromLTRB(12, 12, 0, 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (forecast.events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l10n.forecastNoRecurring,
              style: TextStyle(fontSize: 13.5, color: colors.inkSecondary),
            ),
          ),
        for (final e in forecast.events.take(_maxEvents))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              spacing: 12,
              children: [
                SizedBox(
                  width: 58,
                  child: Text(_day(context, e.date), style: dateStyle),
                ),
                Icon(AppIcons.repeat, size: 14, color: colors.inkTertiary),
                Expanded(
                  child: Text(
                    e.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${e.isEstimate ? '≈ ' : ''}${MoneyFormat.signed(e.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: e.amount.value > 0 ? colors.positive : colors.ink,
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.line)),
          ),
          child: Row(
            spacing: 12,
            children: [
              SizedBox(
                width: 58,
                child: Text(l10n.forecastEveryDay, style: dateStyle),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 1,
                  children: [
                    Text(
                      l10n.forecastVariable,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      l10n.forecastVariableHelp,
                      style: TextStyle(fontSize: 12, color: colors.inkTertiary),
                    ),
                  ],
                ),
              ),
              Text(
                '≈ ${MoneyFormat.signed(Money(-forecast.dailyVariable.value))}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// « Comment est calculée cette prévision ? »
class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.forecast});

  final Forecast forecast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final bullets = [
      if (forecast.events.isEmpty)
        l10n.forecastHowNoRecurring
      else
        l10n.forecastHowRecurring,
      l10n.forecastHowVariable(MoneyFormat.amount(forecast.dailyVariable)),
      l10n.forecastHowIncome,
      l10n.forecastHowNoException,
    ];
    final style = TextStyle(
      fontSize: 13.5,
      height: 1.5,
      color: colors.inkSecondary,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(
            l10n.forecastHowTitle,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          for (final b in bullets)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text('•', style: style),
                Expanded(child: Text(b, style: style)),
              ],
            ),
          Text(
            l10n.forecastDisclaimer,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: colors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
