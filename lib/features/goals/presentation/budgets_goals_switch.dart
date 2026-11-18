import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/widgets/segmented_choice.dart';
import '../../../l10n/l10n.dart';

/// Sélecteur « Budgets | Objectifs » en tête de l'onglet Budgets.
class BudgetsGoalsSwitch extends StatelessWidget {
  const BudgetsGoalsSwitch({required this.showGoals, super.key});

  final bool showGoals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedChoice<bool>(
      options: [(false, l10n.budgetsSegment), (true, l10n.goalsSegment)],
      selected: showGoals,
      onChanged: (goals) {
        if (goals == showGoals) return;
        context.go(goals ? AppRoutes.goals : AppRoutes.budgets);
      },
    );
  }
}
