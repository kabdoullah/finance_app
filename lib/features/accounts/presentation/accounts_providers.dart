import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/database/database_providers.dart';
import '../data/accounts_repository.dart';
import '../domain/account.dart';
import '../domain/accounts_summary.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>(
  (ref) => AccountsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final activeAccountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(accountsRepositoryProvider).watchActive(),
);

final archivedAccountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(accountsRepositoryProvider).watchArchived(),
);

final accountProvider = StreamProvider.family<Account?, String>(
  (ref, id) => ref.watch(accountsRepositoryProvider).watchById(id),
);

/// Total, sous-totaux et répartition des comptes actifs.
final accountsSummaryProvider = Provider<AsyncValue<AccountsSummary>>(
  (ref) => ref.watch(activeAccountsProvider).whenData(AccountsSummary.of),
);
