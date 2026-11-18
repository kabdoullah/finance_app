import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/clock.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/money/amount_input_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/segmented_choice.dart';
import '../../../l10n/l10n.dart';
import '../../goals/presentation/goals_providers.dart';
import '../../recurring/presentation/recurring_providers.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/forecast.dart';
import '../domain/purchase_simulation.dart';
import 'forecast_providers.dart';

/// « Simuler un achat » (maquette Simulation) : pure hypothèse, rien n'est
/// enregistré.
class SimulationPage extends ConsumerStatefulWidget {
  const SimulationPage({this.initialLabel, this.initialPrice, super.key});

  /// Achat pré-rempli (lien « Ouvrir la simulation » du Copilote).
  final String? initialLabel;
  final int? initialPrice;

  @override
  ConsumerState<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends ConsumerState<SimulationPage> {
  late final _label = TextEditingController(text: widget.initialLabel);
  late final _price = TextEditingController(
    text: widget.initialPrice == null
        ? null
        : MoneyFormat.amount(Money(widget.initialPrice!)),
  );
  bool _afterIncome = false;
  bool _useSavings = false;

  @override
  void dispose() {
    _label.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = ref.watch(clockProvider)();
    final today = CalendarDate.of(now);
    final history = ref.watch(spendingHistoryProvider).value;
    final forecast = ref.watch(forecastProvider(ForecastHorizon.month));
    final reserved = (ref.watch(reservedByAccountProvider).value ?? const {})
        .values
        .fold(Money.zero, (sum, r) => sum + r);

    // Prochain revenu récurrent dans les 30 jours (« Après « Salaire » »).
    final horizonEnd = DateTime(today.year, today.month, today.day + 30);
    final incomes =
        (ref.watch(recurringOperationsProvider).value ?? const [])
            .where(
              (o) =>
                  o.kind == TransactionKind.income &&
                  o.isActive &&
                  !o.nextDue!.isAfter(horizonEnd),
            )
            .toList()
          ..sort((a, b) => a.nextDue!.compareTo(b.nextDue!));
    final income = incomes.firstOrNull;
    final afterIncome = _afterIncome && income != null;
    final incomeDay = income == null
        ? 0
        : (income.nextDue!.difference(today).inHours / 24).round().clamp(0, 30);

    // Objectif de même nom : « Utiliser mon épargne « Téléphone » ».
    final label = _label.text.trim();
    final goal = (ref.watch(goalsProvider).value ?? const [])
        .where(
          (g) =>
              label.isNotEmpty &&
              g.name.toLowerCase() == label.toLowerCase() &&
              g.saved.value > 0,
        )
        .firstOrNull;
    final useSavings = _useSavings && goal != null;

    final price = AmountInputFormatter.parse(_price.text);
    final days = history?.daysOfHistory(now) ?? 0;
    final simulation =
        forecast == null || price.value <= 0 || days < Forecast.minHistoryDays
        ? null
        : PurchaseSimulation.compute(
            forecast: forecast,
            reserved: reserved,
            price: price,
            purchaseDay: afterIncome ? incomeDay : 0,
            savingsUsed: useSavings ? goal.saved : Money.zero,
          );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.simTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          _Label(l10n.simWhat),
          TextField(
            controller: _label,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: l10n.simWhatHint),
          ),
          const SizedBox(height: 18),
          _Label(l10n.simPrice),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: const [AmountInputFormatter()],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '0',
              suffixText: l10n.currencyLabel,
              suffixStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.inkSecondary,
              ),
            ),
          ),
          if (income != null) ...[
            const SizedBox(height: 18),
            _Label(l10n.simWhen),
            SegmentedChoice<bool>(
              options: [
                (false, l10n.simToday),
                (
                  true,
                  l10n.simAfterIncome(
                    income.name,
                    AppDateFormat.dayMonth(income.nextDue!, locale),
                  ),
                ),
              ],
              selected: afterIncome,
              onChanged: (v) => setState(() => _afterIncome = v),
            ),
          ],
          if (goal != null) ...[
            const SizedBox(height: 14),
            MergeSemantics(
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          l10n.simUseSavings(goal.name),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.simSavingsHelp(MoneyFormat.amount(goal.saved)),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colors.inkTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: useSavings,
                    onChanged: (v) => setState(() => _useSavings = v),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          if (history != null && days < Forecast.minHistoryDays)
            _Message(
              l10n.forecastInsufficientBody,
              title: l10n.forecastInsufficientTitle,
            )
          else if (simulation == null)
            _Message(l10n.simEnterPrice)
          else ...[
            _Result(
              simulation: simulation,
              what: label.isEmpty ? l10n.simThisPurchase : '« $label »',
              when: afterIncome
                  ? l10n.simOnDate(
                      AppDateFormat.dayMonth(income.nextDue!, locale),
                    )
                  : l10n.simTodayLower,
              showAdvice: !useSavings,
            ),
            const SizedBox(height: 10),
            Text(
              '${_reliability(l10n, forecast!, days)} '
              '${l10n.simAvailableNote}',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: colors.inkTertiary,
              ),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: () => context.push(
                AppRoutes.newGoalFor(name: label, target: price.value),
              ),
              icon: const Icon(AppIcons.target, size: 18),
              label: Text(l10n.simCreateGoal),
            ),
          ],
        ],
      ),
    );
  }

  /// « Fiabilité moyenne · estimation basée sur tes 3 derniers mois… »
  static String _reliability(AppLocalizations l10n, Forecast f, int days) {
    final level = switch (f.reliability) {
      ForecastReliability.high => l10n.forecastReliabilityHigh,
      ForecastReliability.medium => l10n.forecastReliabilityMedium,
      ForecastReliability.low => l10n.forecastReliabilityLow,
    };
    final window = days.clamp(1, Forecast.variableWindowDays);
    final period = window >= 60
        ? l10n.simPeriodMonths(window ~/ 30)
        : l10n.simPeriodDays(window);
    return l10n.simReliability(level, period);
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.simulation,
    required this.what,
    required this.when,
    required this.showAdvice,
  });

  final PurchaseSimulation simulation;
  final String what;
  final String when;

  /// « Utiliser ton épargne ou attendre réduirait le risque. »
  final bool showAdvice;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    String day(DateTime d) => AppDateFormat.dayMonth(d, locale);
    String signed(Money m) =>
        m.isNegative ? MoneyFormat.signed(m) : MoneyFormat.amount(m);

    final (title, icon, background, foreground) = switch (simulation.verdict) {
      PurchaseVerdict.possible => (
        l10n.simPossible,
        AppIcons.checkCircleBold,
        colors.primarySoft,
        colors.onPrimarySoft,
      ),
      PurchaseVerdict.tight => (
        l10n.simTight,
        AppIcons.warningCircleBold,
        colors.warningSoft,
        colors.warning,
      ),
      PurchaseVerdict.discouraged => (
        l10n.simDiscouraged,
        AppIcons.xCircleBold,
        colors.negativeSoft,
        colors.negative,
      ),
    };
    final explain = switch (simulation.verdict) {
      PurchaseVerdict.possible => l10n.simExplainOk(
        MoneyFormat.amount(simulation.lowest),
        day(simulation.endDate),
      ),
      PurchaseVerdict.tight => l10n.simExplainTight(
        MoneyFormat.amount(simulation.lowest),
        day(simulation.lowestDate),
      ),
      PurchaseVerdict.discouraged => [
        l10n.simExplainNeg(what, when, day(simulation.negativeOn!)),
        if (showAdvice) l10n.simExplainNegAdvice,
      ].join(' '),
    };
    Widget cell(String label, Money value, String note) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 3,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.5, color: colors.inkSecondary),
        ),
        Text(
          signed(value),
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: value.isNegative ? colors.negative : colors.ink,
          ),
        ),
        Text(note, style: TextStyle(fontSize: 12, color: colors.inkSecondary)),
      ],
    );

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            Row(
              spacing: 10,
              children: [
                Icon(icon, size: 22, color: foreground),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ],
            ),
            Text(
              AppDateFormat.sentence(explain),
              style: TextStyle(fontSize: 14, height: 1.5, color: colors.ink),
            ),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: foreground.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Expanded(
                    child: cell(
                      l10n.simLowest,
                      simulation.lowest,
                      l10n.simLowestOn(day(simulation.lowestDate)),
                    ),
                  ),
                  Expanded(
                    child: cell(
                      l10n.simBalanceOn(day(simulation.endDate)),
                      simulation.endBalance,
                      l10n.simWithout(signed(simulation.endWithout)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.title});

  final String text;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.chip,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          if (title case final t?)
            Text(
              t,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: context.colors.inkSecondary,
      ),
    ),
  );
}
