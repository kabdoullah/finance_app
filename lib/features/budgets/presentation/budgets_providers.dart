import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/money/money.dart';
import '../../../core/time/month.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_providers.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../data/budgets_repository.dart';
import '../domain/budget.dart';

final budgetsRepositoryProvider = Provider<BudgetsRepository>(
  (ref) => BudgetsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final budgetsProvider = StreamProvider<List<Budget>>(
  (ref) => ref.watch(budgetsRepositoryProvider).watchAll(),
);

/// Vue des budgets du mois en cours (`null` tant que les données chargent).
final budgetsOverviewProvider = Provider<BudgetsOverview?>((ref) {
  final month = Month.of(ref.watch(clockProvider)());
  final budgets = ref.watch(budgetsProvider).value;
  final transactions = ref.watch(monthTransactionsProvider(month)).value;
  final groups = ref.watch(categoryGroupsProvider(CategoryKind.expense)).value;
  if (budgets == null || transactions == null || groups == null) return null;
  return BudgetsOverview.of(
    budgets: budgets,
    monthTransactions: transactions,
    expenseCategories: [
      for (final g in groups)
        if (!g.category.isHidden) g.category,
    ],
  );
});

/// Moyenne des dépenses des 3 derniers mois (`null` = toutes les dépenses).
final averageSpendingProvider = FutureProvider.autoDispose
    .family<Money, String?>(
      (ref, categoryId) => ref
          .watch(budgetsRepositoryProvider)
          .averageMonthlySpending(categoryId),
    );
