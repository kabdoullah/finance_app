import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/motion.dart';
import '../../../core/clock.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/month.dart';
import '../../../core/widgets/motion.dart';
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
String spendingMonthLabel(
  RelativeDate relative,
  Month month, {
  bool withYear = false,
}) => [
  [
    RelativeDate.capitalize(relative.month(month)),
    if (withYear) '${month.year}',
  ].join(' '),
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

  /// Sens du dernier changement de mois (1 suivant, -1 précédent).
  int _direction = 1;

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
    final from = _month ?? ref.read(monthOfProvider)(_now);
    _direction = month.compareTo(from) >= 0 ? 1 : -1;
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
                  style: AppText.sheetTitle.bold.copyWith(letterSpacing: -0.2),
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
                // Maquette : « Novembre 2026 ».
                spendingMonthLabel(relative, month, withYear: true),
                textAlign: TextAlign.center,
                style: AppText.body.bold,
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
          // Maquette : grille, légende (mois déplié) et bascule dans une carte.
          Container(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                // Changement de mois : la grille glisse dans le sens choisi.
                AnimatedSwitcher(
                  duration: Motion.of(context, Motion.slow),
                  switchInCurve: Motion.easeOut,
                  switchOutCurve: Motion.easeIn,
                  transitionBuilder: (child, animation) {
                    final incoming = child.key == ValueKey(month);
                    final from = Offset(
                      0.15 * _direction * (incoming ? 1 : -1),
                      0,
                    );
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: from,
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...previous, ?current],
                  ),
                  child: SpendingCalendarGrid(
                    key: ValueKey(month),
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
                ),
                if (_expanded)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: _Legend(),
                  ),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      foregroundColor: colors.ink,
                      textStyle: AppText.bodySmall.semibold,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        Flexible(
                          child: Text(
                            _expanded ? l10n.calCollapse : l10n.calSeeMonth,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Icon(
                          _expanded
                              ? AppIcons.caretUpBold
                              : AppIcons.caretDownBold,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.base),
            switchInCurve: Motion.ease,
            switchOutCurve: Motion.easeIn,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            child: _DayPanel(
              key: ValueKey((month, selected)),
              month: month,
              spending: spending,
              day: selected,
              now: now,
              masked: masked,
              relative: relative,
            ),
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
                    style: AppText.small.semibold.copyWith(
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
                style: AppText.body.copyWith(
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
                        color: colors.expense.withValues(
                          alpha: _opacity[level],
                        ),
                      ),
                    ),
                  if (hasDue) _DueMark(late: hasLate),
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
            style: AppText.tag.copyWith(color: colors.inkSecondary),
          ),
        ),
      ],
    );
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        item(
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.expense,
            ),
          ),
          l10n.calLegendPaid,
        ),
        item(const _DueMark(late: false), l10n.calLegendPlanned),
        item(const _DueMark(late: true), l10n.calLegendLate),
      ],
    );
  }
}

/// Échéance d'un jour : anneau si planifiée, carré plein si en retard. La
/// forme distingue le retard des dépenses (point plein), pas seulement la
/// couleur.
class _DueMark extends StatelessWidget {
  const _DueMark({required this.late});

  final bool late;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 7,
      height: 7,
      decoration: late
          ? BoxDecoration(
              color: colors.warning,
              borderRadius: BorderRadius.circular(1.5),
            )
          : BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(width: 1.5, color: colors.infoMid),
            ),
    );
  }
}

/// Jour choisi : dépenses à payer puis opérations du jour.
class _DayPanel extends ConsumerWidget {
  const _DayPanel({
    required this.month,
    super.key,
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
        style: AppText.body.copyWith(color: colors.inkSecondary),
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
    // Maquette : « Dimanche 15 novembre · aujourd'hui ».
    final daysAgo = CalendarDate.of(now).difference(day).inDays;
    final title = [
      RelativeDate.capitalize(
        DateFormat(
          'EEEE d MMMM',
          Localizations.localeOf(context).toLanguageTag(),
        ).format(day),
      ),
      if (daysAgo == 0) l10n.dayToday.toLowerCase(),
      if (daysAgo == 1) l10n.dayYesterday.toLowerCase(),
    ].join(' · ');
    final empty = dues.isEmpty && operations.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 10,
            children: [
              Expanded(child: Text(title, style: AppText.bodyLarge.bold)),
              if (summary.isNotEmpty)
                Flexible(
                  child: Text(
                    summary,
                    textAlign: TextAlign.end,
                    style: AppText.label.copyWith(color: colors.inkSecondary),
                  ),
                ),
            ],
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
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              spacing: 10,
              children: [
                Icon(
                  AppIcons.calendarBlank,
                  size: 18,
                  color: colors.inkTertiary,
                ),
                Expanded(
                  child: Text(
                    spending.isEmpty
                        ? l10n.calDayEmptyMonth(monthName)
                        : day.isAfter(today)
                        ? l10n.calDayEmptyFuture
                        : l10n.calDayEmpty,
                    style: AppText.bodySmall.copyWith(
                      color: colors.inkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Action rapide sous le jour : planifier (à venir) ou ajouter une
        // dépense déjà payée (aujourd'hui, passé).
        if (!day.isAfter(today) || dues.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push(
                day.isAfter(today)
                    ? AppRoutes.newTransaction(
                        kind: TransactionKind.expense,
                        plannedDue: day,
                      )
                    : AppRoutes.newTransaction(
                        kind: TransactionKind.expense,
                        paidOn: day,
                      ),
              ),
              icon: Icon(AppIcons.plusBold, size: 14, color: colors.info),
              label: Text(
                day.isAfter(today) ? l10n.calPlanThisDay : l10n.calAddThisDay,
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 44),
                foregroundColor: colors.ink,
                textStyle: AppText.body.semibold,
              ),
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
    Widget cell(String label, Money value, Color color) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(
            label,
            style: AppText.small.copyWith(color: colors.inkSecondary),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CountingValue(
              value: value.value,
              builder: (context, v) => Text(
                amount(Money(v)),
                style: AppText.sectionTitle.bold.copyWith(color: color),
              ),
            ),
          ),
        ],
      ),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        // Maquette : titre et chevron, tout le bloc ouvre Dépenses du mois.
        if (showTitle)
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.spendTitle(monthName),
                  style: AppText.body.bold,
                ),
              ),
              if (onOpen != null)
                Icon(AppIcons.caretRight, size: 14, color: colors.inkTertiary),
            ],
          ),
        Row(
          spacing: 12,
          children: [
            cell(l10n.spendPaid, spending.paid, colors.expense),
            cell(l10n.spendPlanned, spending.planned, colors.info),
            cell(l10n.spendTotal, spending.total, colors.ink),
          ],
        ),
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: total == 0
                  ? ColoredBox(color: colors.chip)
                  : FillIn(
                      value: 1,
                      builder: (context, progress) => Align(
                        alignment: Alignment.centerLeft,
                        // Align et Row relâchent la hauteur : sans
                        // heightFactor et stretch, la barre ferait 0 px.
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          heightFactor: 1,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (spending.paid.value > 0)
                                Expanded(
                                  flex: spending.paid.value,
                                  child: ColoredBox(color: colors.expenseMid),
                                ),
                              if (spending.planned.value > 0)
                                Expanded(
                                  flex: spending.planned.value,
                                  child: ColoredBox(
                                    color: late
                                        ? colors.warning
                                        : colors.infoMid,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        Text(
          note,
          style: AppText.label.prose.copyWith(color: colors.inkSecondary),
        ),
      ],
    );
    if (onOpen == null) return content;
    return Semantics(
      button: true,
      hint: l10n.spendSeeMonth(monthName),
      child: InkWell(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.line)),
          ),
          child: content,
        ),
      ),
    );
  }
}
