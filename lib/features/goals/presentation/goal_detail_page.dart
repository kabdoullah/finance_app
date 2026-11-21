import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/motion.dart';
import '../../../core/clock.dart';
import '../../../core/errors/result.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/l10n.dart';
import '../../recurring/domain/recurring_operation.dart';
import '../../recurring/presentation/recurring_providers.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/goal_draft.dart';
import '../domain/savings_goal.dart';
import 'goal_icons.dart';
import 'goal_movement_sheet.dart';
import 'goals_page.dart';
import 'goals_providers.dart';

/// Détail d'un objectif (maquette Objectif-Detail).
class GoalDetailPage extends ConsumerWidget {
  const GoalDetailPage({required this.goalId, super.key});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final goal = ref.watch(goalProvider(goalId));
    if (goal == null) return Scaffold(appBar: AppBar());
    final now = ref.watch(clockProvider)();
    final date = goal.targetDate;
    final perMonth = goal.perMonth(now);
    final perWeek = goal.perWeek(now);
    final pace = ref.watch(goalPaceProvider(goalId)).value;
    final (note, late) = goalNote(
      goal,
      now,
      l10n,
      emergencyTarget: goal.iconKey == emergencyGoalIcon
          ? ref.watch(emergencyTargetProvider).value
          : null,
    );
    final advice = late && !goal.isOverdue(now)
        ? _Advice.of(ref, goal, now, pace)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.editGoal(goalId)),
            child: Text(l10n.goalEdit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          8,
          AppSpacing.gutter,
          40,
        ),
        children: [
          // Le montant compte après une contribution.
          CountingValue(
            value: goal.saved.value,
            duration: Motion.chart,
            builder: (context, saved) => Text.rich(
              TextSpan(
                text: '${MoneyFormat.amount(Money(saved))} ',
                children: [
                  TextSpan(
                    text: l10n.goalsOfTarget(MoneyFormat.amount(goal.target)),
                    style: AppText.bodyLarge.semibold.copyWith(
                      letterSpacing: 0,
                      color: colors.inkSecondary,
                    ),
                  ),
                ],
              ),
              style: AppText.amount(38, inline: true),
            ),
          ),
          const SizedBox(height: 12),
          GoalBar(goal: goal, height: 10),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.goalLeft(MoneyFormat.amount(goal.left)),
                  style: AppText.label.copyWith(color: colors.inkSecondary),
                ),
              ),
              Flexible(
                child: Text(
                  date == null
                      ? l10n.goalNoDue
                      : l10n.goalTargetDateValue(
                          AppDateFormat.dayMonthYear(date, locale),
                        ),
                  textAlign: TextAlign.end,
                  style: AppText.label.copyWith(color: colors.inkSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => showGoalMovementSheet(
                    context,
                    goal,
                    GoalMovementKind.contribution,
                  ),
                  icon: const Icon(AppIcons.plusBold, size: 16),
                  label: Text(l10n.goalAdd),
                ),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: goal.saved.value <= 0
                      ? null
                      : () => showGoalMovementSheet(
                          context,
                          goal,
                          GoalMovementKind.withdrawal,
                        ),
                  icon: const Icon(AppIcons.minusBold, size: 16),
                  label: Text(l10n.goalWithdraw),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Un seul panneau : effort, note et mention du calcul.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                if (perMonth != null && perWeek != null) ...[
                  Text(l10n.goalEffort, style: AppText.bodyLarge.semibold),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: _EffortCell(
                          value: '≈ ${MoneyFormat.amount(perMonth)}',
                          unit: l10n.goalPerMonth,
                        ),
                      ),
                      Expanded(
                        child: _EffortCell(
                          value: '≈ ${MoneyFormat.amount(perWeek)}',
                          unit: l10n.goalPerWeek,
                        ),
                      ),
                    ],
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: late ? colors.warningSoft : colors.chip,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Icon(
                        late ? AppIcons.warningCircleBold : AppIcons.info,
                        size: 17,
                        color: late ? colors.warning : colors.inkSecondary,
                      ),
                      Expanded(
                        child: Text(
                          [
                            note,
                            if (pace != null && pace.value > 0)
                              l10n.goalPace(MoneyFormat.amount(pace)),
                            ?advice?.text(l10n, locale),
                          ].join(' '),
                          style: AppText.bodySmall.prose.copyWith(
                            color: late ? colors.warning : colors.inkSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (advice?.postpone case (final newDate, _)?)
                  OutlinedButton(
                    onPressed: () => _postpone(context, ref, goal, newDate),
                    child: Text(
                      l10n.goalPostponeButton(
                        AppDateFormat.dayMonthYear(newDate, locale),
                      ),
                    ),
                  ),
                Text(
                  l10n.goalComputedBy,
                  style: AppText.small.copyWith(color: colors.inkTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(l10n.goalHistory, style: AppText.sectionTitle),
          const SizedBox(height: 4),
          _History(goalId: goalId),
        ],
      ),
    );
  }
}

/// Repousse la date cible (bouton « Repousser au … »).
Future<void> _postpone(
  BuildContext context,
  WidgetRef ref,
  SavingsGoal goal,
  DateTime date,
) async {
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).toLanguageTag();
  final messenger = ScaffoldMessenger.of(context);
  final result = await ref
      .read(goalsRepositoryProvider)
      .update(
        goal.id,
        GoalDraft(
          name: goal.name,
          target: goal.target,
          iconKey: goal.iconKey,
          targetDate: date,
        ),
      );
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          result is Ok
              ? l10n.goalPostponed(AppDateFormat.dayMonthYear(date, locale))
              : l10n.errorGeneric,
        ),
      ),
    );
}

/// Conseil « Pour tenir la date : verse X FCFA le jour de « Salaire »
/// (le 1er), ou repousse la date au … (≈ Y par mois). »
class _Advice {
  const _Advice({
    required this.perMonth,
    required this.income,
    required this.postpone,
  });

  /// [pace] : rythme réel (3 mois) ; à défaut, le reste moyen par mois.
  static _Advice? of(
    WidgetRef ref,
    SavingsGoal goal,
    DateTime now,
    Money? pace,
  ) {
    final perMonth = goal.perMonth(now);
    if (perMonth == null) return null;
    final incomes =
        (ref.watch(recurringOperationsProvider).value ?? const [])
            .where((o) => o.kind == TransactionKind.income && o.isActive)
            .toList()
          ..sort((a, b) => a.nextDue!.compareTo(b.nextDue!));
    final capacity = pace != null && pace.value > 0
        ? pace
        : ref.watch(averageSurplusProvider).value;
    return _Advice(
      perMonth: perMonth,
      income: incomes.firstOrNull,
      postpone: capacity == null ? null : goal.postponeFor(now, capacity),
    );
  }

  final Money perMonth;
  final RecurringOperation? income;
  final (DateTime, Money)? postpone;

  String text(AppLocalizations l10n, String locale) {
    final amount = MoneyFormat.amount(perMonth);
    final first = switch (income) {
      final op? => l10n.goalAdviceIncome(
        amount,
        op.name,
        op.nextDue!.day == 1 ? '1er' : '${op.nextDue!.day}',
      ),
      null => l10n.goalAdviceMonthly(amount),
    };
    final second = switch (postpone) {
      (final date, final cost)? => l10n.goalAdvicePostpone(
        AppDateFormat.dayMonth(date, locale),
        MoneyFormat.amount(cost),
      ),
      null => '',
    };
    return AppDateFormat.sentence('$first$second.');
  }
}

class _EffortCell extends StatelessWidget {
  const _EffortCell({required this.value, required this.unit});

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 2,
    children: [
      Text(value, style: AppText.title),
      Text(
        unit,
        style: AppText.caption.copyWith(color: context.colors.inkSecondary),
      ),
    ],
  );
}

class _History extends ConsumerWidget {
  const _History({required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final movements = ref.watch(goalMovementsProvider(goalId)).value;
    if (movements == null) return const SizedBox.shrink();
    if (movements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          l10n.goalHistoryEmpty,
          style: AppText.body.copyWith(color: colors.inkSecondary),
        ),
      );
    }
    final relative = RelativeDate(
      l10n,
      Localizations.localeOf(context).toLanguageTag(),
      ref.watch(clockProvider)(),
    );
    return Column(
      children: [
        for (final m in movements)
          _MovementRow(movement: m, relative: relative),
      ],
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement, required this.relative});

  final GoalMovement movement;
  final RelativeDate relative;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isIn = movement.kind == GoalMovementKind.contribution;
    final day = RelativeDate.capitalize(relative.day(movement.occurredAt));
    final account = isIn
        ? l10n.goalFromAccount(movement.accountName)
        : l10n.goalToAccount(movement.accountName);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isIn ? colors.primarySoft : colors.chip,
            ),
            child: Icon(
              isIn ? AppIcons.plusBold : AppIcons.minusBold,
              size: 15,
              color: isIn ? colors.onPrimarySoft : colors.inkSecondary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  isIn ? l10n.goalContribution : l10n.goalWithdrawal,
                  style: AppText.bodyLarge.semibold,
                ),
                Text(
                  '$day · $account',
                  style: AppText.caption.copyWith(color: colors.inkSecondary),
                ),
              ],
            ),
          ),
          Text(
            MoneyFormat.signed(movement.signed),
            style: AppText.bodyLarge.semibold.copyWith(
              color: isIn ? colors.positive : colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
