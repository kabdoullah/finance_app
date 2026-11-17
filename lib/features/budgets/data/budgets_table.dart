// Les contraintes CHECK de drift référencent la colonne dans sa propre
// définition : faux positif connu de ce lint.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../../categories/data/categories_table.dart';

/// Budgets mensuels : un budget global (catégorie `NULL`) et au plus un
/// budget par catégorie principale. Le montant dépensé n'est jamais stocké.
@DataClassName('BudgetRow')
@TableIndex.sql(
  // Un seul budget par catégorie, et un seul budget global (NULL).
  'CREATE UNIQUE INDEX budgets_category_unique '
  "ON budgets (COALESCE(category_id, ''))",
)
class Budgets extends Table {
  TextColumn get id => text()();

  /// Catégorie principale suivie ; `NULL` = toutes les dépenses.
  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Limite mensuelle en FCFA.
  IntColumn get limitAmount =>
      integer().check(limitAmount.isBetweenValues(1, 999999999))();

  /// Seuil d'avertissement (« M'avertir quand j'atteins »).
  IntColumn get alertPercent =>
      integer().check(alertPercent.isBetweenValues(50, 100))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
