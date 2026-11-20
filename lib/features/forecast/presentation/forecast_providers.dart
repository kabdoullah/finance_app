import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/database/database_providers.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../planned/presentation/planned_providers.dart';
import '../../recurring/presentation/recurring_providers.dart';
import '../data/forecast_repository.dart';
import '../domain/forecast.dart';

final forecastRepositoryProvider = Provider<ForecastRepository>(
  (ref) => ForecastRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final spendingHistoryProvider = StreamProvider<SpendingHistory>(
  (ref) => ref.watch(forecastRepositoryProvider).watchHistory(),
);

/// Prévision pour un horizon (`null` tant que les données chargent).
final forecastProvider = Provider.family<Forecast?, ForecastHorizon>((
  ref,
  horizon,
) {
  final summary = ref.watch(accountsSummaryProvider).value;
  final history = ref.watch(spendingHistoryProvider).value;
  final recurring = ref.watch(recurringOperationsProvider).value;
  final planned = ref.watch(plannedExpensesProvider).value;
  if (summary == null ||
      history == null ||
      recurring == null ||
      planned == null) {
    return null;
  }
  return Forecast.compute(
    now: ref.watch(clockProvider)(),
    horizon: horizon,
    balance: summary.total,
    history: history,
    recurring: recurring,
    planned: planned,
  );
});
