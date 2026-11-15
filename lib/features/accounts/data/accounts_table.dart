// Les contraintes CHECK de drift référencent la colonne dans sa propre
// définition : faux positif connu de ce lint.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

/// Comptes financiers. Dates en epoch ms UTC, montants en FCFA entiers.
@DataClassName('AccountRow')
@TableIndex.sql(
  // Pas deux comptes actifs du même nom (« payé avec Wave » doit être clair).
  'CREATE UNIQUE INDEX accounts_active_name_unique '
  'ON accounts (lower(name)) WHERE archived_at IS NULL',
)
class Accounts extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 40)();

  /// Valeurs de `AccountType.storageValue`.
  TextColumn get type => text().check(
    type.isIn(const ['cash', 'mobile_money', 'bank', 'savings']),
  )();

  IntColumn get openingBalance =>
      integer().check(openingBalance.isBiggerOrEqualValue(0))();

  IntColumn get archivedAt => integer().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
