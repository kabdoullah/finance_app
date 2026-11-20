import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/month.dart';
import '../../forecast/presentation/forecast_providers.dart';
import '../../recurring/presentation/recurring_providers.dart';
import '../../settings/presentation/settings_providers.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../data/planned_repository.dart';
import '../domain/month_spending.dart';
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

/// Mois consultables (calendrier, Dépenses du mois) : du mois de la
/// première opération à 12 mois après le mois en cours.
final spendingMonthsProvider = Provider<(Month, Month)>((ref) {
  final monthOf = ref.watch(monthOfProvider);
  final current = monthOf(ref.watch(clockProvider)());
  final first = ref.watch(spendingHistoryProvider).value?.firstDay;
  var last = current;
  for (var i = 0; i < monthsAhead; i++) {
    last = last.next;
  }
  final start = first == null ? current : monthOf(first);
  return (start.compareTo(current) < 0 ? start : current, last);
});

const monthsAhead = 12;

/// Dépenses à payer (planifiées et échéances récurrentes) jusqu'à la fin
/// du dernier mois consultable ; `null` pendant le chargement.
final duesProvider = Provider<List<DueItem>?>((ref) {
  final planned = ref.watch(plannedExpensesProvider).value;
  final recurring = ref.watch(recurringOperationsProvider).value;
  if (planned == null || recurring == null) return null;
  final (_, last) = ref.watch(spendingMonthsProvider);
  final end = last.end;
  return DueItem.collect(
    planned: planned,
    recurring: recurring,
    until: CalendarDate.of(DateTime(end.year, end.month, end.day - 1)),
  );
});

/// Dépenses d'un mois ; `null` pendant le chargement.
final monthSpendingProvider = Provider.family<MonthSpending?, Month>((
  ref,
  month,
) {
  final transactions = ref.watch(monthTransactionsProvider(month)).value;
  final dues = ref.watch(duesProvider);
  if (transactions == null || dues == null) return null;
  return MonthSpending.of(
    month: month,
    transactions: transactions,
    dues: dues,
    now: ref.watch(clockProvider)(),
  );
});
