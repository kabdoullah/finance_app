import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/time/month.dart';
import '../data/transactions_repository.dart';
import '../domain/transaction.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>(
  (ref) => TransactionsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final monthTransactionsProvider =
    StreamProvider.family<List<Transaction>, Month>(
      (ref, month) =>
          ref.watch(transactionsRepositoryProvider).watchMonth(month),
    );

/// Opérations d'une période (début inclus, fin exclue).
final periodTransactionsProvider =
    StreamProvider.family<List<Transaction>, (DateTime, DateTime)>(
      (ref, range) => ref
          .watch(transactionsRepositoryProvider)
          .watchBetween(range.$1, range.$2),
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

/// Demande d'ouverture de l'onglet Transactions filtré sur une catégorie
/// principale (« Voir les opérations » d'un budget). La page l'applique sur
/// le mois en cours puis la consomme.
final transactionsCategoryRequestProvider =
    NotifierProvider<TransactionsCategoryRequest, String?>(
      TransactionsCategoryRequest.new,
    );

/// Demande d'ouverture de l'onglet Transactions sur un mois (« Voir les
/// opérations » de Dépenses du mois), consommée par la page.
final transactionsMonthRequestProvider =
    NotifierProvider<TransactionsMonthRequest, Month?>(
      TransactionsMonthRequest.new,
    );

class TransactionsMonthRequest extends Notifier<Month?> {
  @override
  Month? build() => null;

  void request(Month month) => state = month;

  void clear() => state = null;
}

class TransactionsCategoryRequest extends Notifier<String?> {
  @override
  String? build() => null;

  void request(String categoryId) => state = categoryId;

  void clear() => state = null;
}
