import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/month.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../l10n/l10n.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_icons.dart';
import '../domain/transaction.dart';
import '../domain/transaction_period.dart';

/// Filtres de la feuille « Filtres » : type, catégorie principale, compte
/// (`null` = tous).
@immutable
class TransactionFilters {
  const TransactionFilters({this.kind, this.categoryId, this.accountId});

  final TransactionKind? kind;
  final String? categoryId;
  final String? accountId;

  int get count =>
      (kind == null ? 0 : 1) +
      (categoryId == null ? 0 : 1) +
      (accountId == null ? 0 : 1);

  TransactionFilters copyWith({
    (TransactionKind?,)? kind,
    (String?,)? categoryId,
    (String?,)? accountId,
  }) => TransactionFilters(
    kind: kind == null ? this.kind : kind.$1,
    categoryId: categoryId == null ? this.categoryId : categoryId.$1,
    accountId: accountId == null ? this.accountId : accountId.$1,
  );
}

/// Feuille « Filtres » : retourne les filtres choisis, ou `null` si elle
/// est fermée sans « Voir … ». [countFor] donne le nombre d'opérations
/// affichées pour des filtres.
Future<TransactionFilters?> showTransactionFilters(
  BuildContext context, {
  required TransactionFilters initial,
  required List<Category> expenseCategories,
  required List<Category> incomeCategories,
  required List<Account> accounts,
  required int Function(TransactionFilters filters) countFor,
}) => showModalBottomSheet<TransactionFilters>(
  context: context,
  useRootNavigator: true,
  showDragHandle: true,
  isScrollControlled: true,
  backgroundColor: context.colors.surface,
  builder: (sheetContext) {
    var draft = initial;
    return StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        final colors = sheetContext.colors;
        final l10n = sheetContext.l10n;
        void update(TransactionFilters next) =>
            setSheetState(() => draft = next);
        Widget section(String title, List<Widget> pills) => Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text(
                title,
                style: AppText.label.semibold.copyWith(
                  color: colors.inkSecondary,
                ),
              ),
              Wrap(spacing: 8, runSpacing: 8, children: pills),
            ],
          ),
        );
        // Catégories proposées selon le type choisi.
        final categories = switch (draft.kind) {
          TransactionKind.income => incomeCategories,
          TransactionKind.transfer => const <Category>[],
          _ => [
            ...expenseCategories,
            if (draft.kind == null) ...incomeCategories,
          ],
        };
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(l10n.txFilters, style: AppText.sheetTitle),
                      ),
                      TextButton(
                        onPressed: draft.count == 0
                            ? null
                            : () => update(const TransactionFilters()),
                        child: Text(l10n.txFiltersReset),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      0,
                      AppSpacing.gutter,
                      16,
                    ),
                    children: [
                      section(l10n.txFilterType, [
                        for (final (kind, label) in [
                          (null, l10n.txFilterAll),
                          (TransactionKind.expense, l10n.txFilterExpense),
                          (TransactionKind.income, l10n.txFilterIncome),
                          (TransactionKind.transfer, l10n.txFilterTransfer),
                        ])
                          ChoicePill(
                            label: label,
                            selected: draft.kind == kind,
                            onTap: () => update(
                              draft.copyWith(
                                kind: (kind,),
                                // Une catégorie d'un autre type ne correspond
                                // plus.
                                categoryId: (null,),
                              ),
                            ),
                          ),
                      ]),
                      if (categories.isNotEmpty)
                        section(l10n.txFilterCategory, [
                          ChoicePill(
                            label: l10n.txFilterAllCategoriesShort,
                            selected: draft.categoryId == null,
                            onTap: () =>
                                update(draft.copyWith(categoryId: (null,))),
                          ),
                          for (final category in categories)
                            ChoicePill(
                              label: category.name,
                              icon: categoryIcon(category.iconKey),
                              selected: draft.categoryId == category.id,
                              onTap: () => update(
                                draft.copyWith(categoryId: (category.id,)),
                              ),
                            ),
                        ]),
                      section(l10n.txFilterAccount, [
                        ChoicePill(
                          label: l10n.txFilterAllAccountsShort,
                          selected: draft.accountId == null,
                          onTap: () =>
                              update(draft.copyWith(accountId: (null,))),
                        ),
                        for (final account in accounts)
                          ChoicePill(
                            label: account.isArchived
                                ? l10n.txArchivedAccount(account.name)
                                : account.name,
                            selected: draft.accountId == account.id,
                            onTap: () => update(
                              draft.copyWith(accountId: (account.id,)),
                            ),
                          ),
                      ]),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    12,
                    AppSpacing.gutter,
                    8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.line)),
                  ),
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(draft),
                    child: Text(l10n.txShowCount(countFor(draft))),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  },
);

/// Feuille « Période » : dates choisies au calendrier (un premier toucher
/// pour le début, un second pour la fin) ou raccourcis.
Future<TransactionPeriod?> showPeriodPicker(
  BuildContext context, {
  required TransactionPeriod initial,
  required DateTime now,
  required Month Function(DateTime) monthOf,
}) => showModalBottomSheet<TransactionPeriod>(
  context: context,
  useRootNavigator: true,
  showDragHandle: true,
  isScrollControlled: true,
  backgroundColor: context.colors.surface,
  builder: (sheetContext) {
    var first = initial.start;
    var last = initial.last;
    var shown = DateTime(first.year, first.month);
    var awaitingEnd = false;
    final today = CalendarDate.of(now);
    DateTime day(int offset) =>
        DateTime(today.year, today.month, today.day + offset);
    final thisMonth = monthOf(now);
    final presets = <(String Function(AppLocalizations), DateTime, DateTime)>[
      ((l) => l.txRangeLast7, day(-6), today),
      (
        (l) => l.txRangeThisMonth,
        thisMonth.start,
        DateTime(
          thisMonth.end.year,
          thisMonth.end.month,
          thisMonth.end.day - 1,
        ),
      ),
      ((l) => l.txRangeNext30, day(1), day(30)),
      ((l) => l.txRangeLast3Months, thisMonth.previous.previous.start, today),
    ];
    return StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        final colors = sheetContext.colors;
        final l10n = sheetContext.l10n;
        final locale = Localizations.localeOf(sheetContext).toLanguageTag();
        final relative = RelativeDate(l10n, locale, now);
        void pick(DateTime d) => setSheetState(() {
          if (!awaitingEnd) {
            first = last = d;
            awaitingEnd = true;
          } else if (d.isBefore(first)) {
            last = first;
            first = d;
            awaitingEnd = false;
          } else {
            last = d;
            awaitingEnd = false;
          }
        });
        final offset = shown.weekday - 1;
        final daysInMonth = DateTime(shown.year, shown.month + 1, 0).day;
        final cells = <DateTime?>[
          for (var i = 0; i < offset; i++) null,
          for (var d = 1; d <= daysInMonth; d++)
            DateTime(shown.year, shown.month, d),
        ];
        while (cells.length % 7 != 0) {
          cells.add(null);
        }
        Widget bound(String label, DateTime date, bool active) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                width: active ? 2 : 1,
                color: active ? colors.primary : colors.line,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  label,
                  style: AppText.small.copyWith(color: colors.inkSecondary),
                ),
                Text(
                  RelativeDate.capitalize(
                    '${DateFormat('EEE', locale).format(date)} '
                    '${AppDateFormat.dayMonth(date, locale)}',
                  ),
                  style: AppText.body.semibold,
                ),
              ],
            ),
          ),
        );
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              0,
              AppSpacing.gutter,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Text(l10n.txRangeTitle, style: AppText.sheetTitle),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (label, a, b) in presets)
                      ChoicePill(
                        label: label(l10n),
                        height: 34,
                        selected: first == a && last == b,
                        onTap: () => setSheetState(() {
                          first = a;
                          last = b;
                          awaitingEnd = false;
                          shown = DateTime(a.year, a.month);
                        }),
                      ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: l10n.calPrevMonth,
                      onPressed: () => setSheetState(
                        () => shown = DateTime(shown.year, shown.month - 1),
                      ),
                      icon: const Icon(AppIcons.caretLeftBold, size: 16),
                    ),
                    Expanded(
                      child: Text(
                        RelativeDate.capitalize(
                          DateFormat('MMMM y', locale).format(shown),
                        ),
                        textAlign: TextAlign.center,
                        style: AppText.bodyLarge.semibold,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.calNextMonth,
                      onPressed: () => setSheetState(
                        () => shown = DateTime(shown.year, shown.month + 1),
                      ),
                      icon: const Icon(AppIcons.caretRightBold, size: 16),
                    ),
                  ],
                ),
                Column(
                  spacing: 2,
                  children: [
                    for (var w = 0; w < cells.length; w += 7)
                      Row(
                        children: [
                          for (final d in cells.sublist(w, w + 7))
                            Expanded(
                              child: d == null
                                  ? const SizedBox(height: 44)
                                  : _RangeDay(
                                      day: d,
                                      label: relative.longDate(d),
                                      isBound: d == first || d == last,
                                      inRange:
                                          !d.isBefore(first) &&
                                          !d.isAfter(last),
                                      isToday: d == today,
                                      onTap: () => pick(d),
                                    ),
                            ),
                        ],
                      ),
                  ],
                ),
                Row(
                  spacing: 10,
                  children: [
                    bound(l10n.txRangeFrom, first, !awaitingEnd),
                    bound(l10n.txRangeTo, last, awaitingEnd),
                  ],
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(sheetContext)
                          .pop(TransactionPeriod.custom(first, last)),
                  child: Text(l10n.txRangeApply),
                ),
              ],
            ),
          ),
        );
      },
    );
  },
);

class _RangeDay extends StatelessWidget {
  const _RangeDay({
    required this.day,
    required this.label,
    required this.isBound,
    required this.inRange,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final String label;
  final bool isBound;
  final bool inRange;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: inRange,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: inRange
                ? colors.primarySoft.withValues(alpha: isBound ? 1 : 0.55)
                : null,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              width: 1.5,
              color: isBound
                  ? colors.primary
                  : isToday
                  ? colors.line
                  : Colors.transparent,
            ),
          ),
          child: Text(
            '${day.day}',
            style: AppText.body.copyWith(
              fontWeight: inRange ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
