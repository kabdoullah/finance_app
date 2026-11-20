// Les contraintes CHECK de drift référencent la colonne dans sa propre
// définition : faux positif connu de ce lint.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../../accounts/data/accounts_table.dart';
import '../../categories/data/categories_table.dart';

/// Dépenses planifiées encore à payer. Elles ne changent aucun solde : une
/// fois payée, la dépense devient une opération (qui garde sa date prévue)
/// et quitte cette table. Dates calendaires locales « AAAA-MM-JJ ».
@DataClassName('PlannedExpenseRow')
@TableIndex(name: 'planned_expenses_due', columns: {#dueDate})
class PlannedExpenses extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 80)();

  IntColumn get amount =>
      integer().check(amount.isBetweenValues(1, 999999999))();

  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.restrict)();

  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.cascade)();

  TextColumn get dueDate => text()();

  TextColumn get note => text().nullable().withLength(min: 1, max: 80)();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
