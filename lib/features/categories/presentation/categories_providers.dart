import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/database/database_providers.dart';
import '../data/categories_repository.dart';
import '../domain/category.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

/// Catégories d'un type avec leurs sous-catégories (masquées comprises).
final categoryGroupsProvider =
    StreamProvider.family<List<CategoryGroup>, CategoryKind>(
      (ref, kind) => ref.watch(categoriesRepositoryProvider).watchGroups(kind),
    );
