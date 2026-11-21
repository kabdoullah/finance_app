import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/clock.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../l10n/l10n.dart';
import '../../budgets/domain/budget.dart';
import '../../budgets/presentation/budgets_providers.dart';
import '../../forecast/domain/forecast.dart';
import '../../forecast/presentation/forecast_providers.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_period.dart';
import '../../transactions/presentation/transactions_providers.dart';

/// Semaines de référence pour « vs moy. ».
const _averageWeeks = 12;

/// « Cette semaine » (maquette Assistant) : chiffres calculés par
/// l'application, disponibles même sans l'assistant IA — dépensé depuis
/// lundi (et l'écart avec la moyenne), reste par jour du budget global,
/// point bas prévu sur 30 jours.
class WeekCard extends ConsumerWidget {
  const WeekCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = ref.watch(clockProvider)();
    final week = TransactionPeriod.week(now);
    final earlier = DateTime(
      week.start.year,
      week.start.month,
      week.start.day - 7 * _averageWeeks,
    );
    Money spentOf(List<Transaction>? list) => (list ?? const [])
        .where((t) => t.kind == TransactionKind.expense)
        .fold(Money.zero, (sum, t) => sum + t.amount);
    final spent = spentOf(
      ref.watch(periodTransactionsProvider((week.start, week.end))).value,
    );
    final before = ref
        .watch(periodTransactionsProvider((earlier, week.start)))
        .value;
    // Moyenne d'une semaine entière, ramenée aux jours écoulés de celle-ci.
    final elapsed = CalendarDate.of(now).difference(week.start).inDays + 1;
    final average = before == null || before.isEmpty
        ? null
        : Money(spentOf(before).value * elapsed ~/ (7 * _averageWeeks));

    final overview = ref.watch(budgetsOverviewProvider);
    final global = overview?.global;
    final perDay = global == null
        ? null
        : dailyAllowance(global.remaining, overview!.month.daysLeft(now));
    final lastDay = overview?.month.end.subtract(const Duration(days: 1));

    final history = ref.watch(spendingHistoryProvider).value;
    final forecast =
        history != null && history.daysOfHistory(now) >= Forecast.minHistoryDays
        ? ref.watch(forecastProvider(ForecastHorizon.month))
        : null;
    (Money, DateTime)? low;
    if (forecast != null && forecast.points.length > 1) {
      var index = 1;
      for (var d = 2; d < forecast.points.length; d++) {
        if (forecast.points[d].value < forecast.points[index].value) index = d;
      }
      final today = CalendarDate.of(now);
      low = (
        forecast.points[index],
        DateTime(today.year, today.month, today.day + index),
      );
    }

    String short(DateTime d) => AppDateFormat.dayMonth(d, locale);
    // Valeurs approchées, arrondies comme sur la maquette.
    Money round(Money m, int step) => Money((m.value / step).round() * step);
    final diff = average == null ? null : round(spent - average, 100);
    final cells = [
      (
        l10n.asWeekSpent,
        MoneyFormat.amount(spent),
        diff == null ? '' : l10n.asVsAverage(MoneyFormat.signed(diff)),
        diff != null && diff.value > 0 ? colors.expense : colors.inkTertiary,
      ),
      (
        l10n.asPerDayLeft,
        perDay == null ? '—' : '≈\u00a0${MoneyFormat.amount(perDay)}',
        lastDay == null || perDay == null
            ? ''
            : AppDateFormat.sentence(l10n.asUntil(short(lastDay))),
        colors.inkTertiary,
      ),
      (
        l10n.asLowPoint,
        low == null ? '—' : '≈\u00a0${MoneyFormat.amount(round(low.$1, 1000))}',
        low == null ? '' : AppDateFormat.sentence(l10n.asOnDate(short(low.$2))),
        colors.inkTertiary,
      ),
    ];

    return Semantics(
      label: l10n.asWeekLabel(cells[2].$2, cells[1].$2, cells[0].$2),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            // Passe sur deux lignes avec un texte agrandi.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              children: [
                Text(
                  l10n.asWeekTitle.toUpperCase(),
                  style: AppText.overline.bold.copyWith(
                    color: colors.inkTertiary,
                  ),
                ),
                Text(
                  l10n.asComputedNow,
                  style: AppText.small.copyWith(color: colors.inkTertiary),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                for (final (label, value, sub, subColor) in cells)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          label,
                          style: AppText.caption.copyWith(
                            color: colors.inkSecondary,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(value, style: AppText.sectionTitle),
                        ),
                        if (sub.isNotEmpty)
                          Text(
                            sub,
                            style: AppText.tag.copyWith(color: subColor),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
