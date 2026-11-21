import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/clock.dart';
import '../../../core/errors/result.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../l10n/l10n.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../categories/presentation/category_icons.dart';
import '../../settings/presentation/settings_providers.dart';
import '../domain/planned_expense.dart';
import 'planned_labels.dart';
import 'planned_providers.dart';
import 'spending_calendar.dart';

/// Détail d'une dépense planifiée à payer (maquette Planifiee-Detail) :
/// statut, dates, effet sur les dépenses, puis « Marquer comme payée »,
/// « Modifier » et « Supprimer » (annulable).
class PlannedDetailPage extends ConsumerStatefulWidget {
  const PlannedDetailPage({required this.plannedId, super.key});

  final String plannedId;

  @override
  ConsumerState<PlannedDetailPage> createState() => _PlannedDetailPageState();
}

class _PlannedDetailPageState extends ConsumerState<PlannedDetailPage> {
  /// Dépense supprimée, gardée pour « Annuler la suppression ».
  PlannedExpense? _deleted;
  bool _busy = false;

  String _monthName(BuildContext context, DateTime date) => RelativeDate(
    context.l10n,
    Localizations.localeOf(context).toLanguageTag(),
    ref.read(clockProvider)(),
  ).month(ref.read(monthOfProvider)(date));

  Future<void> _pay(PlannedExpense expense) async {
    final paidOn = await _showPaySheet(context, expense);
    if (paidOn == null || !mounted) return;
    setState(() => _busy = true);
    final result = await ref
        .read(plannedRepositoryProvider)
        .pay(expense.id, paidOn);
    if (!mounted) return;
    setState(() => _busy = false);
    final l10n = context.l10n;
    switch (result) {
      case Ok(:final value):
        _showMessage(
          l10n.plannedPaidToast(
            expense.accountName,
            MoneyFormat.amount(expense.amount),
            expense.name,
          ),
        );
        context.pushReplacement(AppRoutes.transactionDetail(value.id));
      case Err(failure: ValidationFailure()):
        _showMessage(l10n.txAccountUnavailable);
      case Err():
        _showMessage(l10n.errorGeneric);
    }
  }

  Future<void> _delete(PlannedExpense expense) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.plannedDeleteTitle(expense.name),
      message: l10n.plannedDeleteBody(_monthName(context, expense.dueDate)),
      confirmLabel: l10n.txDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final result = await ref.read(plannedRepositoryProvider).delete(expense.id);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _deleted = value);
      case Err():
        _showMessage(l10n.errorGeneric);
    }
  }

  Future<void> _undo() async {
    final result = await ref.read(plannedRepositoryProvider).restore(_deleted!);
    if (!mounted) return;
    switch (result) {
      case Ok():
        setState(() => _deleted = null);
      case Err():
        _showMessage(context.l10n.errorGeneric);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final deleted = _deleted;
    if (deleted != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.plannedTitle)),
        body: _DeletedView(
          name: deleted.name,
          month: _monthName(context, deleted.dueDate),
          onUndo: _undo,
        ),
      );
    }
    return switch (ref.watch(plannedExpenseProvider(widget.plannedId))) {
      AsyncData(value: final expense?) => _view(context, expense),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.plannedNotFound)),
      ),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.errorGeneric)),
      ),
      _ => Scaffold(appBar: AppBar()),
    };
  }

  Widget _view(BuildContext context, PlannedExpense expense) {
    final colors = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = ref.watch(clockProvider)();
    final relative = RelativeDate(l10n, locale, now);
    final status = expense.statusOn(now);
    final late = status == PlannedStatus.late;
    final month = relative.month(ref.watch(monthOfProvider)(expense.dueDate));
    final (iconBg, iconFg) = status.colors(colors);
    final category = expense.category;
    final parent = expense.parentCategory;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.plannedTitle),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.editPlanned(expense.id)),
            child: Text(l10n.accountEditAction),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  12,
                  AppSpacing.gutter,
                  24,
                ),
                children: [
                  Column(
                    spacing: 8,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: iconBg,
                        ),
                        child: Icon(
                          categoryIcon(expense.mainCategory.iconKey),
                          size: 24,
                          color: iconFg,
                        ),
                      ),
                      Text(
                        expense.name,
                        textAlign: TextAlign.center,
                        style: AppText.bodyLarge.semibold,
                      ),
                      Text.rich(
                        TextSpan(
                          text: '${MoneyFormat.amount(expense.amount)} ',
                          children: [
                            TextSpan(
                              text: l10n.currencyLabel,
                              style: AppText.subtitle.copyWith(
                                letterSpacing: 0,
                                color: colors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                        style: AppText.amount(38),
                      ),
                      PlannedStatusPill(status: status),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _InfoRow(
                    label: l10n.plannedDue,
                    value: relative.longDate(expense.dueDate),
                    valueColor: late ? colors.warning : null,
                  ),
                  _InfoRow(
                    label: l10n.plannedPaidOn,
                    value: l10n.plannedNotYet,
                    valueColor: colors.inkTertiary,
                  ),
                  _InfoRow(
                    label: l10n.plannedCreated,
                    value: relative.longDate(expense.createdAt),
                  ),
                  _InfoRow(label: l10n.txAccount, value: expense.accountName),
                  _InfoRow(
                    label: l10n.txCategory,
                    value: parent == null
                        ? category.name
                        : '${parent.name} › ${category.name}',
                  ),
                  if (expense.note != null)
                    _InfoRow(label: l10n.plannedNoteRow, value: expense.note!),
                  const SizedBox(height: 16),
                  _ImpactBox(
                    late: late,
                    title: late
                        ? l10n.plannedImpactLateTitle
                        : l10n.plannedImpactPlannedTitle(month),
                    text: late
                        ? l10n.plannedImpactLateText(month)
                        : AppDateFormat.sentence(
                            l10n.plannedImpactPlannedText(
                              AppDateFormat.dayMonth(expense.dueDate, locale),
                              month,
                            ),
                          ),
                  ),
                  for (final month in {
                    ref.watch(monthOfProvider)(now),
                    ref.watch(monthOfProvider)(expense.dueDate),
                  })
                    if (ref.watch(monthSpendingProvider(month))
                        case final spending?)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: MonthSpendingSummary(
                          spending: spending,
                          now: now,
                          masked: ref.watch(amountsHiddenProvider),
                        ),
                      ),
                  if (ref.watch(accountsSummaryProvider).value
                      case final summary?)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _InfoRow(
                        label: l10n.plannedRealBalance,
                        value: ref.watch(amountsHiddenProvider)
                            ? MoneyFormat.masked
                            : '${MoneyFormat.amount(summary.total)} '
                                  '${l10n.currencyLabel}',
                      ),
                    ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 6,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _pay(expense),
                    icon: const Icon(AppIcons.checkBold, size: 18),
                    label: Text(l10n.plannedMarkPaid),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _delete(expense),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      foregroundColor: colors.negative,
                    ),
                    child: Text(l10n.txDelete),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Feuille « Marquer comme payée » : date réelle (aujourd'hui, hier, ou la
  /// date prévue si elle est plus ancienne), compte et effet sur les mois.
  Future<DateTime?> _showPaySheet(
    BuildContext context,
    PlannedExpense expense,
  ) {
    final now = ref.read(clockProvider)();
    final today = CalendarDate.of(now);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final monthOf = ref.read(monthOfProvider);
    return showModalBottomSheet<DateTime>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (sheetContext) {
        var picked = today;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final colors = sheetContext.colors;
            final l10n = sheetContext.l10n;
            final locale = Localizations.localeOf(sheetContext).toLanguageTag();
            final relative = RelativeDate(l10n, locale, now);
            String short(DateTime d) => AppDateFormat.dayMonth(d, locale);
            final options = [
              (today, l10n.plannedPayToday(short(today))),
              (yesterday, l10n.plannedPayYesterday(short(yesterday))),
              if (expense.dueDate.isBefore(yesterday))
                (expense.dueDate, l10n.plannedPayOnDue(short(expense.dueDate))),
            ];
            final paidMonth = monthOf(picked);
            final dueMonth = monthOf(expense.dueDate);
            final early = paidMonth.compareTo(dueMonth) < 0;
            final afterDue = picked.isAfter(expense.dueDate);
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  0,
                  AppSpacing.gutter,
                  16,
                ),
                children: [
                  Text(l10n.plannedMarkPaid, style: AppText.sheetTitle),
                  const SizedBox(height: 16),
                  _SheetLabel(l10n.plannedPayDate),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (date, label) in options)
                        ChoiceChip(
                          label: Text(label),
                          selected: date == picked,
                          onSelected: (_) => setSheetState(() => picked = date),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SheetLabel(l10n.plannedPaidFrom),
                  Text(
                    l10n.plannedPaidFromValue(
                      expense.accountName,
                      MoneyFormat.amount(expense.amount),
                    ),
                    style: AppText.bodyLarge.semibold,
                  ),
                  if (early || afterDue) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.chip,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            if (early) ...[
                              TextSpan(
                                text: '${l10n.plannedPayEarlyTitle} ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: AppDateFormat.sentence(
                                  l10n.plannedPayEarlyText(
                                    short(expense.dueDate),
                                    relative.month(dueMonth),
                                    short(picked),
                                    relative.month(paidMonth),
                                  ),
                                ),
                              ),
                            ] else
                              TextSpan(
                                text: AppDateFormat.sentence(
                                  l10n.plannedPayLateText(short(picked)),
                                ),
                              ),
                          ],
                        ),
                        style: AppText.bodySmall.prose.copyWith(
                          color: colors.inkSecondary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(picked),
                    child: Text(l10n.plannedPayConfirm),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    style: TextButton.styleFrom(minimumSize: const Size(0, 52)),
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: AppText.label.medium.copyWith(color: context.colors.inkSecondary),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text(label, style: AppText.body.copyWith(color: colors.inkSecondary)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppText.bodyLarge.semibold.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// « Comptée en décembre, pas avant » / « Toujours à payer ».
class _ImpactBox extends StatelessWidget {
  const _ImpactBox({
    required this.late,
    required this.title,
    required this.text,
  });

  final bool late;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ink = late ? colors.warning : colors.ink;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: late ? colors.warningSoft : colors.chip,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Icon(
            late ? AppIcons.warningCircleBold : AppIcons.calendarBlank,
            size: 18,
            color: ink,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(title, style: AppText.body.semibold.copyWith(color: ink)),
                Text(
                  text,
                  style: AppText.bodySmall.prose.copyWith(
                    color: colors.inkSecondary,
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

class _DeletedView extends StatelessWidget {
  const _DeletedView({
    required this.name,
    required this.month,
    required this.onUndo,
  });

  final String name;
  final String month;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        80,
        AppSpacing.gutter,
        24,
      ),
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.chip,
            ),
            child: Icon(AppIcons.trash, size: 26, color: colors.inkSecondary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.plannedDeletedTitle,
          textAlign: TextAlign.center,
          style: AppText.headline,
        ),
        const SizedBox(height: 10),
        Text(
          l10n.plannedDeletedBody(month, name),
          textAlign: TextAlign.center,
          style: AppText.body.prose.copyWith(color: colors.inkSecondary),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: onUndo,
            icon: const Icon(AppIcons.arrowCounterClockwise, size: 18),
            label: Text(l10n.txUndo),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () => context.go(AppRoutes.transactions),
            child: Text(l10n.txBackToList),
          ),
        ),
      ],
    );
  }
}
