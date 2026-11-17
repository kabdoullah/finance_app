import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/time/month.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/domain/category.dart';
import '../data/transactions_repository.dart';
import '../domain/transaction.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>(
  (ref) => TransactionsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final categoryGroupsProvider =
    StreamProvider.family<List<CategoryGroup>, CategoryKind>(
      (ref, kind) => ref.watch(categoriesRepositoryProvider).watchGroups(kind),
    );

final monthTransactionsProvider =
    StreamProvider.family<List<Transaction>, Month>(
      (ref, month) =>
          ref.watch(transactionsRepositoryProvider).watchMonth(month),
    );

final recentTransactionsProvider = StreamProvider<List<Transaction>>(
  (ref) => ref.watch(transactionsRepositoryProvider).watchRecent(4),
);

final accountTransactionsProvider =
    StreamProvider.family<List<Transaction>, String>(
      (ref, accountId) =>
          ref.watch(transactionsRepositoryProvider).watchForAccount(accountId),
    );

final transactionProvider = StreamProvider.family<Transaction?, String>(
  (ref, id) => ref.watch(transactionsRepositoryProvider).watchById(id),
);

final hasTransactionsProvider = StreamProvider<bool>(
  (ref) => ref.watch(transactionsRepositoryProvider).watchHasAny(),
);
