import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/clock.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/month.dart';
import '../../../l10n/l10n.dart';
import '../../settings/presentation/settings_providers.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/presentation/transaction_labels.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../domain/month_spending.dart';
import '../domain/planned_expense.dart';
import 'planned_labels.dart';
import 'planned_providers.dart';

/// Nom d'un mois budgétaire : « Novembre », « Novembre · 25 oct. – 24 nov. ».
String spendingMonthLabel(RelativeDate relative, Month month) => [
  RelativeDate.capitalize(relative.month(month)),
  ?relative.monthRange(month),
].join(' · ');

/// Section « Calendrier » de l'accueil (maquette Main) : grille du mois
/// budgétaire, jour choisi et ses dépenses, puis « Dépenses de … ».
class SpendingCalendar extends ConsumerStatefulWidget {
  const SpendingCalendar({super.key});

  @override
  ConsumerState<SpendingCalendar> createState() => _SpendingCalendarState();
}

class _SpendingCalendarState extends ConsumerState<SpendingCalendar> {
  Month? _month;
  DateTime? _selected;
  bool _expanded = false;

  DateTime get _now => ref.read(clockProvider)();

  /// Jour choisi en arrivant sur un mois : aujourd'hui pour le mois en
  /// cours, la première dépense à payer d'un mois futur, le dernier jour
  /// payé d'un mois passé.
  DateTime? _defaultDay(Month month, MonthSpending? spending) {
    final current = ref.read(monthOfProvider)(_now);
    if (month == current) return CalendarDate.of(_now);
    if (spending == null) return null;
    if (month.compareTo(current) > 0) return spending.dues.firstOrNull?.date;
    final days = spending.spentByDay.keys.toList()..sort();
    return days.lastOrNull;
  }

  void _go(Month month) => setState(() {
    _month = month;
    _selected = _defaultDay(month, ref.read(monthSpendingProvider(month)));
  });

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
    final current = ref.watch(monthOfProvider)(now);
    // Début du mois budgétaire changé : retour au mois en cours.
    if (_month != null && _month!.startDay != current.startDay) {
      _month = null;
    }
    final month = _month ?? current;
    final selected = _month == null ? CalendarDate.of(now) : _selected;
    final (first, last) = ref.watch(spendingMonthsProvider);
    final spending = ref.watch(monthSpendingProvider(month));
    final masked = ref.watch(amountsHiddenProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.calTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.calPrevMonth,
              onPressed: month.compareTo(first) > 0
                  ? () => _go(month.previous)
                  : null,
              icon: const Icon(AppIcons.caretLeftBold, size: 16),
            ),
            Flexible(
              child: Text(
                spendingMonthLabel(relative, month),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.calNextMonth,
              onPressed: month.compareTo(last) < 0
                  ? () => _go(month.next)
                  : null,
              icon: const Icon(AppIcons.caretRightBold, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (spending != null) ...[
          SpendingCalendarGrid(
            month: month,
            spending: spending,
            selected: selected,
            now: now,
            expanded: _expanded,
            onSelect: (day) => setState(() {
              _month = month;
              _selected = day;
            }),
          ),
          const SizedBox(height: 8),
          const _Legend(),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? AppIcons.caretUpBold : AppIcons.caretDownBold,
                size: 14,
              ),
              label: Text(_expanded ? l10n.calCollapse : l10n.calSeeMonth),
            ),
          ),
          Divider(height: 24, color: colors.line),
          _DayPanel(
            month: month,
            spending: spending,
            day: selected,
            now: now,
            masked: masked,
            relative: relative,
          ),
          const SizedBox(height: 20),
          MonthSpendingSummary(
            spending: spending,
            now: now,
            masked: masked,
            onOpen: () => context.push(AppRoutes.monthSpending(month)),
          ),
        ],
      ],
    );
  }
}

/// Grille du mois budgétaire (lundi en premier). Repliée : seule la
/// semaine du jour choisi.
class SpendingCalendarGrid extends StatelessWidget {
  const SpendingCalendarGrid({
    required this.month,
    required this.spending,
    required this.selected,
    required this.now,
    required this.expanded,
    required this.onSelect,
    super.key,
  });

  final Month month;
  final MonthSpending spending;
  final DateTime? selected;
  final DateTime now;
  final bool expanded;
  final ValueChanged<DateTime> onSelect;

  /// Semaines de la période, `null` hors période.
  List<List<DateTime?>> _weeks() {
    final start = month.start;
    final days = [
      for (var i = 0; i < month.length; i++)
        DateTime(start.year, start.month, start.day + i),
    ];
    final cells = <DateTime?>[
      for (var i = 1; i < start.weekday; i++) null,
      ...days,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return [for (var i = 0; i < cells.length; i += 7) cells.sublist(i, i + 7)];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final weeks = _weeks();
    final shown = expanded
        ? weeks
        : [
            weeks.firstWhere(
              (w) => w.contains(selected),
              orElse: () => weeks.first,
            ),
          ];
    // Initiales des jours, lundi en premier.
    final letters = [
      for (var d = 0; d < 7; d++)
        DateFormat('EEEEE', locale).format(DateTime(2026, 11, 16 + d)),
    ];
    return Column(
      spacing: 4,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (final letter in letters)
                Expanded(
                  child: Text(
                    letter.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.inkTertiary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (final week in shown)
          Row(
            children: [
              for (final day in week)
                Expanded(
                  child: day == null
                      ? const SizedBox(height: 48)
                      : _DayCell(
                          day: day,
                          spent: spending.spentByDay[day] ?? 0,
                          dues: spending.duesOn(day),
                          selected: day == selected,
                          now: now,
                          onTap: () => onSelect(day),
                        ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.spent,
    required this.dues,
    required this.selected,
    required this.now,
    required this.onTap,
  });

  final DateTime day;
  final int spent;
  final List<DueItem> dues;
  final bool selected;
  final DateTime now;
  final VoidCallback onTap;

  static const _opacity = [0.0, 0.38, 0.68, 1.0];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final today = CalendarDate.of(now);
    final isToday = day == today;
    final level = MonthSpending.intensity(spent);
    final hasLate = dues.any((d) => d.statusOn(now) == PlannedStatus.late);
    final hasDue = dues.isNotEmpty;
    final relative = RelativeDate(
      l10n,
      Localizations.localeOf(context).toLanguageTag(),
      now,
    );
    final details = [
      if (spent > 0) l10n.calDaySpentShort(MoneyFormat.amount(Money(spent))),
      if (hasLate)
        l10n.calDayLateShort
      else if (hasDue)
        l10n.calDayPlannedShort,
    ].join();
    return Semantics(
      button: true,
      selected: selected,
      label: l10n.calDaySemantics(relative.longDate(day), details),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 6),
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: selected ? colors.primarySoft : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: 1.5,
              color: selected
                  ? colors.primary
                  : isToday
                  ? colors.line
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 4,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday || selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: day.isAfter(today) ? colors.inkSecondary : colors.ink,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 3,
                children: [
                  if (level > 0)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary.withValues(
                          alpha: _opacity[level],
                        ),
                      ),
                    ),
                  if (hasDue)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasLate ? colors.warning : null,
                        border: Border.all(
                          width: 1.5,
                          color: hasLate ? colors.warning : colors.inkSecondary,
                        ),
                      ),
                    ),
                  if (level == 0 && !hasDue) const SizedBox(height: 7),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    Widget item(Widget mark, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        mark,
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 11.5, color: colors.inkSecondary),
          ),
        ),
      ],
    );
    Widget dot(Color fill, Color border) => Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(width: 1.5, color: border),
      ),
    );
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        item(dot(colors.primary, colors.primary), l10n.calLegendPaid),
        item(
          dot(Colors.transparent, colors.inkSecondary),
          l10n.calLegendPlanned,
        ),
        item(dot(colors.warning, colors.warning), l10n.calLegendLate),
      ],
    );
  }
}

/// Jour choisi : dépenses à payer puis opérations du jour.
class _DayPanel extends ConsumerWidget {
  const _DayPanel({
    required this.month,
    required this.spending,
    required this.day,
    required this.now,
    required this.masked,
    required this.relative,
  });

  final Month month;
  final MonthSpending spending;
  final DateTime? day;
  final DateTime now;
  final bool masked;
  final RelativeDate relative;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final day = this.day;
    final today = CalendarDate.of(now);
    final monthName = relative.month(month);
    if (day == null) {
      return Text(
        spending.isEmpty ? l10n.calDayEmptyMonth(monthName) : l10n.calDayEmpty,
        style: TextStyle(fontSize: 14, color: colors.inkSecondary),
      );
    }
    final dues = spending.duesOn(day);
    final operations = [
      for (final t
          in ref.watch(monthTransactionsProvider(month)).value ??
              const <Transaction>[])
        if (CalendarDate.of(t.occurredAt.toLocal()) == day) t,
    ];
    final spent = spending.spentByDay[day] ?? 0;
    final due = dues.fold(0, (sum, d) => sum + d.amount.value);
    String amount(int value) =>
        masked ? MoneyFormat.masked : MoneyFormat.amount(Money(value));
    final summary = [
      if (spent > 0) l10n.calDaySpent(amount(spent)),
      if (due > 0)
        day.isBefore(today)
            ? l10n.calDayLate(amount(due))
            : l10n.calDayDue(amount(due)),
    ].join(' · ');
    final title = relative.header(day);
    final empty = dues.isEmpty && operations.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        if (summary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              summary,
              style: TextStyle(fontSize: 13, color: colors.inkSecondary),
            ),
          ),
        for (final d in dues)
          DueRow(
            due: d,
            now: now,
            masked: masked,
            meta: dueMeta(l10n, relative, d, now),
          ),
        for (final t in operations)
          TransactionTile(
            transaction: t,
            masked: masked,
            onTap: () => context.push(AppRoutes.transactionDetail(t.id)),
          ),
        if (empty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              spending.isEmpty
                  ? l10n.calDayEmptyMonth(monthName)
                  : day.isAfter(today)
                  ? l10n.calDayEmptyFuture
                  : l10n.calDayEmpty,
              style: TextStyle(fontSize: 14, color: colors.inkSecondary),
            ),
          ),
        if (day.isAfter(today) && dues.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push(
                AppRoutes.newTransaction(
                  kind: TransactionKind.expense,
                  plannedDue: day,
                ),
              ),
              icon: const Icon(AppIcons.plusBold, size: 16),
              label: Text(l10n.calPlanThisDay),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ),
      ],
    );
  }
}

/// « Dépenses de novembre » : payées, planifiées, total prévu, une barre
/// et une phrase ; [onOpen] ajoute le lien vers Dépenses du mois.
class MonthSpendingSummary extends ConsumerWidget {
  const MonthSpendingSummary({
    required this.spending,
    required this.now,
    required this.masked,
    this.onOpen,
    this.showTitle = true,
    super.key,
  });

  final MonthSpending spending;
  final DateTime now;
  final bool masked;
  final VoidCallback? onOpen;
  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final relative = RelativeDate(
      l10n,
      Localizations.localeOf(context).toLanguageTag(),
      now,
    );
    final month = spending.month;
    final monthName = relative.month(month);
    final current = ref.watch(monthOfProvider)(now);
    String amount(Money value) =>
        masked ? MoneyFormat.masked : MoneyFormat.amount(value);
    final late = spending.late.value > 0;
    final note = switch (month.compareTo(current)) {
      > 0 => l10n.spendNoteFuture,
      0 =>
        late
            ? l10n.spendNoteCurrentLate(amount(spending.late))
            : l10n.spendNoteCurrent,
      _ =>
        spending.isEmpty
            ? l10n.spendNoteEmpty
            : late
            ? l10n.spendNotePastLate(amount(spending.late))
            : l10n.spendNotePast,
    };
    final total = spending.total.value;
    Widget cell(String label, Money value, {bool strong = false}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.5, color: colors.inkSecondary),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount(value),
              style: TextStyle(
                fontSize: 17,
                fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        if (showTitle)
          Text(
            l10n.spendTitle(monthName),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        Row(
          spacing: 12,
          children: [
            cell(l10n.spendPaid, spending.paid),
            cell(l10n.spendPlanned, spending.planned),
            cell(l10n.spendTotal, spending.total, strong: true),
          ],
        ),
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: total == 0
                  ? ColoredBox(color: colors.chip)
                  : Row(
                      children: [
                        if (spending.paid.value > 0)
                          Expanded(
                            flex: spending.paid.value,
                            child: ColoredBox(color: colors.chart.first),
                          ),
                        if (spending.planned.value > 0)
                          Expanded(
                            flex: spending.planned.value,
                            child: ColoredBox(
                              color: late ? colors.warning : colors.chart.last,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
        Text(
          note,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: colors.inkSecondary,
          ),
        ),
        if (onOpen != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onOpen,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(l10n.spendSeeMonth(monthName)),
            ),
          ),
      ],
    );
  }
}
