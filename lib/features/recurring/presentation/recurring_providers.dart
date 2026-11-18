import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/database/database_providers.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../data/recurring_repository.dart';
import '../domain/recurring_operation.dart';

final recurringRepositoryProvider = Provider<RecurringRepository>(
  (ref) => RecurringRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
    ref.watch(transactionsRepositoryProvider),
  ),
);

final recurringOperationsProvider = StreamProvider<List<RecurringOperation>>(
  (ref) => ref.watch(recurringRepositoryProvider).watchAll(),
);

/// Échéances à confirmer, de la plus ancienne à la plus récente.
final pendingOccurrencesProvider = Provider<List<PendingOccurrence>>((ref) {
  final operations = ref.watch(recurringOperationsProvider).value ?? const [];
  return PendingOccurrence.of(operations, ref.watch(clockProvider)());
});
