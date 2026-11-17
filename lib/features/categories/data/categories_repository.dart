import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/category.dart';

/// Lecture des catégories. Leur gestion (création, renommage) viendra avec la
/// fonctionnalité Catégories.
class CategoriesRepository {
  CategoriesRepository(this._db);

  final AppDatabase _db;

  /// Catégories principales d'un type, chacune avec ses sous-catégories.
  Stream<List<CategoryGroup>> watchGroups(CategoryKind kind) =>
      (_db.select(_db.categories)
            ..where((c) => c.kind.equals(kind.storageValue))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .watch()
          .map((rows) {
            final categories = rows.map(toCategory).toList();
            return [
              for (final main in categories.where((c) => !c.isSubcategory))
                CategoryGroup(
                  category: main,
                  children: [
                    for (final child in categories)
                      if (child.parentId == main.id) child,
                  ],
                ),
            ];
          });

  static Category toCategory(CategoryRow row) => Category(
    id: row.id,
    name: row.name,
    kind: CategoryKind.fromStorage(row.kind),
    iconKey: row.icon,
    parentId: row.parentId,
  );
}
