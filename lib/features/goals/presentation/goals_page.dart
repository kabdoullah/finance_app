import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/motion.dart';
import '../../../core/clock.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/section_tint.dart';
import '../../../l10n/l10n.dart';
import '../domain/savings_goal.dart';
import 'budgets_goals_switch.dart';
import 'goal_icons.dart';
import 'goal_movement_sheet.dart';
import 'goals_providers.dart';

/// Onglet Budgets, vue Objectifs (maquette Objectifs).
class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final goals = ref.watch(goalsProvider).value;

    return Scaffold(
      body: SectionTint(
        color: context.colors.warningTint,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.budgetsTitle,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const BudgetsGoalsSwitch(showGoals: true),
              const SizedBox(height: 24),
              if (goals != null) ...[
                if (goals.isEmpty)
                  Text(
                    l10n.goalsEmpty,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: colors.inkSecondary,
                    ),
                  )
                else ...[
                  _Summary(summary: GoalsSummary.of(goals)),
                  const SizedBox(height: 16),
                  for (final goal in goals) GoalCard(goal: goal),
                ],
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.newGoal),
                  icon: const Icon(AppIcons.plusBold, size: 18),
                  label: Text(l10n.goalNew),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary});

  final GoalsSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Text(
          l10n.goalsSaved,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: colors.inkSecondary,
          ),
        ),
        CountingValue(
          value: summary.saved.value,
          builder: (context, saved) => Text.rich(
            TextSpan(
              text: '${MoneyFormat.amount(Money(saved))} ',
              children: [
                TextSpan(
                  text: l10n.goalsOfTarget(MoneyFormat.amount(summary.target)),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    color: colors.inkSecondary,
                  ),
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w600,
              letterSpacing: -1,
            ),
          ),
        ),
        Text(
          l10n.goalsInProgress(summary.inProgress),
          style: TextStyle(fontSize: 12.5, color: colors.inkTertiary),
        ),
      ],
    );
  }
}

/// Ligne d'un objectif : nom, échéance, Ajouter, progression et note.
class GoalCard extends ConsumerWidget {
  const GoalCard({required this.goal, super.key});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = ref.watch(clockProvider)();
    final date = goal.targetDate;
    final (note, late) = goalNote(
      goal,
      now,
      l10n,
      emergencyTarget: goal.iconKey == emergencyGoalIcon
          ? ref.watch(emergencyTargetProvider).value
          : null,
    );

    // Lignes séparées par un trait, pas de cartes (maquette Objectifs).
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            spacing: 12,
            children: [
              // Objectif atteint : icône pleine ambre, halo unique et
              // retour haptique.
              ReachedHalo(
                reached: goal.isReached,
                color: colors.warning,
                onReached: () => unawaited(Haptics.success()),
                child: AnimatedContainer(
                  duration: Motion.of(context, Motion.slow),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: goal.isReached ? colors.warning : colors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    goalIcon(goal.iconKey),
                    size: 18,
                    color: goal.isReached
                        ? colors.surface
                        : colors.onPrimarySoft,
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => context.go(AppRoutes.goalDetail(goal.id)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Row(
                        spacing: 4,
                        children: [
                          Flexible(
                            child: Text(
                              goal.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            AppIcons.caretRight,
                            size: 14,
                            color: colors.inkTertiary,
                          ),
                        ],
                      ),
                      Text(
                        l10n.goalDueHistory(
                          date == null
                              ? l10n.goalNoDue
                              : l10n.goalDue(
                                  AppDateFormat.dayMonthYear(date, locale),
                                ),
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.inkTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => showGoalMovementSheet(
                  context,
                  goal,
                  GoalMovementKind.contribution,
                ),
                child: Text(l10n.goalAdd),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${MoneyFormat.amount(goal.saved)} ',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Text(
                  l10n.goalSavedOf(MoneyFormat.amount(goal.target)),
                  style: TextStyle(fontSize: 13, color: colors.inkSecondary),
                ),
              ),
              Text(
                '${goal.percent} %',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.inkSecondary,
                ),
              ),
            ],
          ),
          GoalBar(goal: goal),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Icon(
                late ? AppIcons.warningCircleBold : AppIcons.info,
                size: 16,
                color: late ? colors.warning : colors.inkSecondary,
              ),
              Expanded(
                child: Text(
                  note,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: late ? colors.warning : colors.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Note sous la barre d'un objectif ; `true` si elle signale un retard.
///
/// Un fonds d'urgence sans date ajoute « Objectif conseillé : 3 mois de
/// dépenses (≈ [emergencyTarget]) ».
(String, bool) goalNote(
  SavingsGoal goal,
  DateTime now,
  AppLocalizations l10n, {
  Money? emergencyTarget,
}) {
  if (goal.isReached) return (l10n.goalNoteReached, false);
  if (goal.targetDate == null) {
    if (goal.iconKey != emergencyGoalIcon) return (l10n.goalNoteNoDate, false);
    final advice = emergencyTarget == null
        ? l10n.goalEmergencyAdviceNoData
        : l10n.goalEmergencyAdvice(MoneyFormat.amount(emergencyTarget));
    return ('${l10n.goalNoteNoDate} $advice', false);
  }
  if (goal.isOverdue(now)) {
    return (l10n.goalNoteOverdue(MoneyFormat.amount(goal.left)), true);
  }
  final perMonth = MoneyFormat.amount(goal.perMonth(now) ?? goal.left);
  return goal.isLate(now)
      ? (l10n.goalNoteLate(perMonth), true)
      : (l10n.goalNoteOnTrack(perMonth), false);
}

class GoalBar extends StatelessWidget {
  const GoalBar({required this.goal, this.height = 6, super.key});

  final SavingsGoal goal;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: colors.chip,
          child: Align(
            alignment: Alignment.centerLeft,
            // Remplissage depuis la gauche ; suit la contribution.
            child: FillIn(
              value: goal.progress,
              duration: Motion.slow,
              builder: (context, value) => FractionallySizedBox(
                widthFactor: value,
                heightFactor: 1,
                child: ColoredBox(color: colors.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ligne « Objectifs d'épargne · 3 objectifs · 315 000 FCFA mis de côté »
/// en bas de la page Comptes.
class GoalsAccountsLink extends ConsumerWidget {
  const GoalsAccountsLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final goals = ref.watch(goalsProvider).value ?? const [];
    final summary = GoalsSummary.of(goals);
    return InkWell(
      onTap: () => context.go(AppRoutes.goals),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.line)),
        ),
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.chip,
                shape: BoxShape.circle,
              ),
              child: const Icon(AppIcons.piggyBank, size: 19),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    l10n.goalsAccountsLink,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    summary.count == 0
                        ? l10n.goalsInProgress(0)
                        : l10n.goalsAccountsSummary(
                            summary.count,
                            MoneyFormat.amount(summary.saved),
                          ),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.caretRight, size: 16, color: colors.inkTertiary),
          ],
        ),
      ),
    );
  }
}
