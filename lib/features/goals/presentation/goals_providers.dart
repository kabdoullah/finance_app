import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/money/money.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../data/goals_repository.dart';
import '../domain/savings_goal.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>(
  (ref) => GoalsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
    ref.watch(accountsRepositoryProvider),
  ),
);

final goalsProvider = StreamProvider<List<SavingsGoal>>(
  (ref) => ref.watch(goalsRepositoryProvider).watchAll(),
);

final goalProvider = Provider.family<SavingsGoal?, String>(
  (ref, id) =>
      ref.watch(goalsProvider).value?.where((g) => g.id == id).firstOrNull,
);

final goalMovementsProvider = StreamProvider.family<List<GoalMovement>, String>(
  (ref, goalId) => ref.watch(goalsRepositoryProvider).watchMovements(goalId),
);

/// Réservé par compte, tous objectifs confondus.
final reservedByAccountProvider = StreamProvider<Map<String, Money>>(
  (ref) => ref.watch(goalsRepositoryProvider).watchReservedByAccount(),
);

/// Réservé par compte pour un objectif (comptes possibles d'un retrait).
final goalReservedByAccountProvider =
    StreamProvider.family<Map<String, Money>, String>(
      (ref, goalId) => ref
          .watch(goalsRepositoryProvider)
          .watchReservedByAccount(goalId: goalId),
    );

/// « En moyenne, il te reste X FCFA par mois » (`null` sans historique).
final averageSurplusProvider = FutureProvider.autoDispose<Money?>(
  (ref) => ref.watch(goalsRepositoryProvider).averageMonthlySurplus(),
);

/// Rythme d'épargne moyen de l'objectif sur 3 mois, recalculé à chaque
/// mouvement.
final goalPaceProvider = FutureProvider.autoDispose.family<Money?, String>((
  ref,
  goalId,
) {
  ref.watch(goalMovementsProvider(goalId));
  return ref.watch(goalsRepositoryProvider).averageMonthlyContribution(goalId);
});

/// Montant conseillé d'un fonds d'urgence : 3 mois de dépenses, arrondi au
/// millier supérieur (`null` sans historique suffisant).
final emergencyTargetProvider = FutureProvider.autoDispose<Money?>((ref) async {
  final monthly = await ref
      .watch(goalsRepositoryProvider)
      .averageMonthlyExpenses();
  if (monthly == null || monthly.value <= 0) return null;
  return Money((monthly.value * 3 + 999) ~/ 1000 * 1000);
});
