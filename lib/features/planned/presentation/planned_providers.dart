import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/database/database_providers.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../data/planned_repository.dart';
import '../domain/planned_expense.dart';

final plannedRepositoryProvider = Provider<PlannedRepository>(
  (ref) => PlannedRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
    ref.watch(transactionsRepositoryProvider),
  ),
);

/// Dépenses planifiées à payer, par date prévue.
final plannedExpensesProvider = StreamProvider<List<PlannedExpense>>(
  (ref) => ref.watch(plannedRepositoryProvider).watchAll(),
);

final plannedExpenseProvider = StreamProvider.family<PlannedExpense?, String>(
  (ref, id) => ref.watch(plannedRepositoryProvider).watchById(id),
);
