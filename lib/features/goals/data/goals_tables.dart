// Les contraintes CHECK de drift référencent la colonne dans sa propre
// définition : faux positif connu de ce lint.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../../accounts/data/accounts_table.dart';

/// Objectifs d'épargne. Le montant épargné n'est jamais stocké : il découle
/// des mouvements ([GoalMovements]).
@DataClassName('GoalRow')
class SavingsGoals extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 40)();

  /// Clé d'icône (`goalIcon`), déduite de la suggestion choisie.
  TextColumn get iconKey => text()();

  IntColumn get targetAmount =>
      integer().check(targetAmount.isBetweenValues(1, 9999999999))();

  /// Date cible « AAAA-MM-JJ » ; `NULL` = sans date.
  TextColumn get targetDate => text().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Contributions et retraits d'un objectif. Une contribution réserve de
/// l'argent sur un compte (aucune opération, aucun solde modifié) ; un
/// retrait libère cette réserve.
@DataClassName('GoalMovementRow')
@TableIndex(name: 'goal_movements_goal', columns: {#goalId, #occurredAt})
@TableIndex(name: 'goal_movements_account', columns: {#accountId})
class GoalMovements extends Table {
  TextColumn get id => text()();

  TextColumn get goalId =>
      text().references(SavingsGoals, #id, onDelete: KeyAction.cascade)();

  /// `contribution` ou `withdrawal`.
  TextColumn get kind =>
      text().check(kind.isIn(const ['contribution', 'withdrawal']))();

  IntColumn get amount =>
      integer().check(amount.isBetweenValues(1, 9999999999))();

  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.cascade)();

  /// Epoch ms UTC.
  IntColumn get occurredAt => integer()();

  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
