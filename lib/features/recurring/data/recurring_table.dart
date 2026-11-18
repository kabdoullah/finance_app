// Les contraintes CHECK de drift référencent la colonne dans sa propre
// définition : faux positif connu de ce lint.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../../accounts/data/accounts_table.dart';
import '../../categories/data/categories_table.dart';

/// Modèles d'opérations récurrentes (dépenses et revenus). Ils ne changent
/// aucun solde : seules les opérations enregistrées à chaque échéance
/// comptent. Dates calendaires locales au format « AAAA-MM-JJ ».
@DataClassName('RecurringRow')
@TableIndex(name: 'recurring_next_due', columns: {#nextDueDate})
class RecurringOperations extends Table {
  TextColumn get id => text()();

  /// `expense` ou `income` (pas de transfert pour l'instant).
  TextColumn get kind => text().check(kind.isIn(const ['expense', 'income']))();

  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// Montant fixe, ou estimation si [isVariable].
  IntColumn get amount =>
      integer().check(amount.isBetweenValues(1, 999999999))();

  BoolColumn get isVariable => boolean().withDefault(const Constant(false))();

  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.restrict)();

  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.cascade)();

  /// `week`, `month` ou `year` ; l'échéance découle de [startDate].
  TextColumn get frequency =>
      text().check(frequency.isIn(const ['week', 'month', 'year']))();

  TextColumn get startDate => text()();

  /// Dernière date possible ; `NULL` = sans fin.
  TextColumn get endDate => text().nullable()();

  /// Prochaine échéance non traitée ; `NULL` quand le modèle est terminé.
  TextColumn get nextDueDate => text().nullable()();

  BoolColumn get askBeforeRecording =>
      boolean().withDefault(const Constant(true))();

  IntColumn get pausedAt => integer().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
