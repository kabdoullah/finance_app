import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/money/money.dart';
import '../../../l10n/l10n.dart';
import '../../categories/presentation/category_icons.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/presentation/add_transaction_page.dart';
import '../domain/month_spending.dart';
import '../domain/planned_expense.dart';
import 'planned_providers.dart';

extension PlannedStatusLabels on PlannedStatus {
  String label(AppLocalizations l10n) => switch (this) {
    PlannedStatus.planned => l10n.plannedStatusPlanned,
    PlannedStatus.late => l10n.plannedStatusLate,
    PlannedStatus.paid => l10n.plannedStatusPaid,
  };

  /// (fond, encre) de l'icône et de la pastille : neutre à payer, ambre en
  /// retard, vert une fois payée.
  (Color, Color) colors(AppColors colors) => switch (this) {
    // Ardoise : à payer, prévu.
    PlannedStatus.planned => (colors.infoSoft, colors.info),
    PlannedStatus.late => (colors.warningSoft, colors.warning),
    PlannedStatus.paid => (colors.primarySoft, colors.onPrimarySoft),
  };
}

/// Pastille « Planifiée », « En retard » ou « Payée ».
class PlannedStatusPill extends StatelessWidget {
  const PlannedStatusPill({required this.status, super.key});

  final PlannedStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, ink) = status.colors(context.colors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label(context.l10n),
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
    );
  }
}

/// Ligne d'une dépense à payer (planifiée ou échéance récurrente) : ouvre
/// son détail, ou la liste des récurrentes.
class DueRow extends StatelessWidget {
  const DueRow({
    required this.due,
    required this.now,
    required this.meta,
    this.masked = false,
    super.key,
  });

  final DueItem due;
  final DateTime now;
  final String meta;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = due.statusOn(now);
    final (background, ink) = status.colors(colors);
    final isRecurring = due.source == DueSource.recurring;
    return InkWell(
      onTap: () => context.push(
        isRecurring ? AppRoutes.recurring : AppRoutes.plannedDetail(due.id),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: background,
              ),
              child: Icon(
                isRecurring
                    ? AppIcons.repeat
                    : categoryIcon(due.category.iconKey),
                size: 18,
                color: ink,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    due.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 4,
              children: [
                Text(
                  masked
                      ? MoneyFormat.masked
                      : '${due.isEstimate ? '≈ ' : ''}'
                            '${MoneyFormat.amount(due.amount)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.inkSecondary,
                  ),
                ),
                PlannedStatusPill(status: status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ligne secondaire d'une dépense à payer : « Prévue le 12 nov. · Wave »
/// en retard, « Mardi 15 déc. · Ecobank » à venir (« récurrente » en plus).
String dueMeta(
  AppLocalizations l10n,
  RelativeDate relative,
  DueItem due,
  DateTime now,
) {
  final late = due.statusOn(now) == PlannedStatus.late;
  final recurring = due.source == DueSource.recurring;
  final short = AppDateFormat.dayMonth(due.date, relative.locale);
  return AppDateFormat.sentence(switch ((late, recurring)) {
    (true, false) => l10n.plannedLateMeta(due.accountName, short),
    (true, true) => l10n.dueRecurringLateMeta(due.accountName, short),
    (false, false) => l10n.plannedUpcomingMeta(
      due.accountName,
      relative.header(due.date),
    ),
    (false, true) => l10n.dueRecurringMeta(
      due.accountName,
      relative.header(due.date),
    ),
  });
}

/// « Modifier » une dépense planifiée : le formulaire d'ajout, ouvert sur
/// les détails et pré-rempli.
class PlannedEditPage extends ConsumerWidget {
  const PlannedEditPage({required this.plannedId, super.key});

  final String plannedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(plannedExpenseProvider(plannedId))) {
        AsyncData(value: final expense?) => AddTransactionPage(
          initialKind: TransactionKind.expense,
          editPlanned: expense,
        ),
        AsyncData() || AsyncError() => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(context.l10n.plannedNotFound)),
        ),
        _ => Scaffold(appBar: AppBar()),
      };
}
