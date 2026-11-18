import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/clock.dart';
import '../../../core/errors/result.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/money/amount_input_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../l10n/l10n.dart';
import '../../categories/presentation/category_icons.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/recurring_operation.dart';
import 'recurring_labels.dart';
import 'recurring_providers.dart';

/// Liste des opérations récurrentes (maquette Recurrentes) : totaux prévus,
/// échéances à confirmer et modèles.
class RecurringPage extends ConsumerWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final operations = ref.watch(recurringOperationsProvider).value;
    final pending = ref.watch(pendingOccurrencesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recurringTitle)),
      body: operations == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              children: [
                Text.rich(
                  TextSpan(
                    text: l10n.recurringIntroBefore,
                    children: [
                      TextSpan(
                        text: l10n.recurringIntroBold,
                        style: TextStyle(
                          color: colors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: l10n.recurringIntroAfter),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _Totals(totals: RecurringTotals.of(operations)),
                for (final occurrence in pending)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: _PendingCard(occurrence: occurrence),
                  ),
                const SizedBox(height: 24),
                if (operations.isEmpty)
                  Text(
                    l10n.recurringEmpty,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: colors.inkSecondary,
                    ),
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            l10n.recurringModels,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '${operations.where((o) => o.isActive).length}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.inkTertiary,
                        ),
                      ),
                    ],
                  ),
                  for (final operation in operations)
                    _OperationRow(operation: operation),
                ],
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.newRecurring()),
                  icon: const Icon(AppIcons.plusBold, size: 18),
                  label: Text(l10n.recurringNew),
                ),
              ],
            ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.totals});

  final RecurringTotals totals;

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
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: colors.line)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: cell(
                l10n.recurringIncomePerMonth,
                MoneyFormat.signed(totals.income),
                colors.positive,
                const EdgeInsets.fromLTRB(0, 14, 14, 14),
              ),
            ),
            VerticalDivider(width: 1, color: colors.line),
            Expanded(
              child: cell(
                l10n.recurringExpensePerMonth,
                MoneyFormat.signed(Money(-totals.expense.value)),
                colors.ink,
                const EdgeInsets.fromLTRB(14, 14, 0, 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte « À confirmer · échéance hier » : Enregistrer ou Pas ce mois-ci.
class _PendingCard extends ConsumerWidget {
  const _PendingCard({required this.occurrence});

  final PendingOccurrence occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final operation = occurrence.operation;
    final due = occurrence.due;
    final today = CalendarDate.of(ref.watch(clockProvider)());
    final daysAgo = (today.difference(due).inHours / 24).round();
    final dueDay = AppDateFormat.dayMonth(due, locale);
    final label = switch (daysAgo) {
      0 => l10n.recurringPendingToday,
      1 => l10n.recurringPendingYesterday,
      _ => l10n.recurringPendingOn(dueDay),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.warningSoft,
        border: Border.all(color: colors.warning),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 8,
            children: [
              Icon(AppIcons.clockBold, size: 15, color: colors.warning),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colors.warning,
                  ),
                ),
              ),
            ],
          ),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      operation.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n.recurringPendingMeta(dueDay, operation.accountName),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                operation.signedAmount,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (occurrence.isFirst)
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => _record(context, ref),
                    child: Text(l10n.recurringRecord),
                  ),
                ),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => _skip(context, ref),
                    child: Text(operation.recurrence.frequency.skipLabel(l10n)),
                  ),
                ),
              ],
            )
          else
            Text(
              AppDateFormat.sentence(
                l10n.recurringWaitingTurn(
                  AppDateFormat.dayMonth(operation.nextDue!, locale),
                ),
              ),
              style: TextStyle(fontSize: 12.5, color: colors.inkSecondary),
            ),
        ],
      ),
    );
  }

  Future<void> _record(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final operation = occurrence.operation;
    Money? amount;
    if (operation.isVariable) {
      amount = await _askRealAmount(context, operation);
      if (amount == null) return;
    }
    final result = await ref
        .read(recurringRepositoryProvider)
        .record(operation.id, occurrence.due, amount: amount);
    if (!context.mounted) return;
    _showMessage(context, switch (result) {
      Ok(:final value) => l10n.recurringRecordedToast(
        operation.name,
        MoneyFormat.signed(
          value.kind == TransactionKind.income
              ? value.amount
              : Money(-value.amount.value),
        ),
        operation.accountName,
      ),
      Err() => l10n.errorGeneric,
    });
  }

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final result = await ref
        .read(recurringRepositoryProvider)
        .skip(occurrence.operation.id, occurrence.due);
    if (!context.mounted) return;
    _showMessage(
      context,
      result is Ok ? l10n.recurringSkippedToast : l10n.errorGeneric,
    );
  }
}

/// Feuille « Montant réel » d'une échéance à montant variable, pré-remplie
/// avec l'estimation.
Future<Money?> _askRealAmount(
  BuildContext context,
  RecurringOperation operation,
) => showModalBottomSheet<Money>(
  context: context,
  isScrollControlled: true,
  builder: (context) => _RealAmountSheet(operation: operation),
);

class _RealAmountSheet extends StatefulWidget {
  const _RealAmountSheet({required this.operation});

  final RecurringOperation operation;

  @override
  State<_RealAmountSheet> createState() => _RealAmountSheetState();
}

class _RealAmountSheetState extends State<_RealAmountSheet> {
  late final _amount = TextEditingController(
    text: MoneyFormat.amount(widget.operation.amount),
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final amount = AmountInputFormatter.parse(_amount.text);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(
            l10n.recurringRealAmountTitle(widget.operation.name),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: const [AmountInputFormatter()],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              suffixText: l10n.currencyLabel,
              helperText: l10n.recurringRealAmountHelp(
                MoneyFormat.amount(widget.operation.amount),
              ),
              helperStyle: TextStyle(color: colors.inkTertiary),
            ),
          ),
          FilledButton(
            onPressed: amount.value > 0
                ? () => Navigator.of(context).pop(amount)
                : null,
            child: Text(l10n.recurringRecord),
          ),
        ],
      ),
    );
  }
}

/// Ligne de modèle : icône en pointillés, montant, rythme, prochaine
/// échéance et interrupteur pause / réactivation.
class _OperationRow extends ConsumerWidget {
  const _OperationRow({required this.operation});

  final RecurringOperation operation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final next = operation.nextDue;
    final active = operation.isActive;
    final meta = [
      operation.recurrence.meta(l10n, locale),
      operation.accountName,
      if (operation.isVariable) l10n.recurringEstimated,
    ].join(' · ');
    final status = operation.isPaused
        ? l10n.recurringPaused
        : next == null
        ? l10n.recurringFinished
        : l10n.recurringNext(AppDateFormat.dayMonth(next, locale));

    return InkWell(
      onTap: () => context.push(AppRoutes.editRecurring(operation.id)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.line)),
        ),
        child: Row(
          spacing: 12,
          children: [
            Opacity(
              opacity: active ? 1 : 0.6,
              child: CustomPaint(
                painter: _DashedCircle(colors.inkTertiary),
                child: SizedBox.square(
                  dimension: 40,
                  child: Icon(
                    categoryIcon(operation.mainCategory.iconKey),
                    size: 18,
                    color: colors.inkSecondary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Opacity(
                opacity: active ? 1 : 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: '${operation.name}  ',
                        children: [
                          TextSpan(
                            text: operation.signedAmount,
                            style: TextStyle(
                              fontSize: 14,
                              color: operation.kind == TransactionKind.income
                                  ? colors.positive
                                  : colors.ink,
                            ),
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      meta,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.inkTertiary,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? colors.inkSecondary
                            : colors.inkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (next != null || operation.isPaused)
              Switch(
                value: !operation.isPaused,
                onChanged: (on) => _setActive(context, ref, active: on),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _setActive(
    BuildContext context,
    WidgetRef ref, {
    required bool active,
  }) async {
    final l10n = context.l10n;
    final result = await ref
        .read(recurringRepositoryProvider)
        .setPaused(operation.id, paused: !active);
    if (!context.mounted) return;
    _showMessage(
      context,
      result is! Ok
          ? l10n.errorGeneric
          : active
          ? l10n.recurringResumedToast(operation.name)
          : l10n.recurringPausedToast(operation.name),
    );
  }
}

/// Cercle en pointillés des modèles (ils ne sont pas encore des opérations).
class _DashedCircle extends CustomPainter {
  const _DashedCircle(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashes = 18;
    const sweep = math.pi / dashes;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = Offset.zero & size;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect.deflate(0.75), i * 2 * sweep, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCircle oldDelegate) => oldDelegate.color != color;
}

void _showMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
