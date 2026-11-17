// Les contraintes CHECK de drift référencent la colonne dans sa propre
// définition : faux positif connu de ce lint.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

/// Catégories et sous-catégories de dépenses et de revenus.
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 40)();

  /// Valeurs de `CategoryKind.storageValue`.
  TextColumn get kind => text().check(kind.isIn(const ['expense', 'income']))();

  /// Clé d'icône Phosphor (voir `categoryIcon`).
  TextColumn get icon => text()();

  /// Catégorie parente pour une sous-catégorie (un seul niveau).
  TextColumn get parentId => text().nullable().references(Categories, #id)();

  IntColumn get sortOrder => integer()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
