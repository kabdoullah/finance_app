// Les contraintes CHECK de drift référencent la colonne dans sa propre
// définition : faux positif connu de ce lint.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../../accounts/data/accounts_table.dart';
import '../../categories/data/categories_table.dart';

/// Opérations : dépenses, revenus et transferts entre comptes.
/// Montants toujours positifs (le sens vient de `kind`), dates en epoch ms UTC.
@DataClassName('TransactionRow')
@TableIndex(name: 'transactions_account', columns: {#accountId, #occurredAt})
@TableIndex(name: 'transactions_to_account', columns: {#toAccountId})
@TableIndex(name: 'transactions_occurred_at', columns: {#occurredAt})
class Transactions extends Table {
  TextColumn get id => text()();

  /// Valeurs de `TransactionKind.storageValue`.
  TextColumn get kind =>
      text().check(kind.isIn(const ['expense', 'income', 'transfer']))();

  IntColumn get amount =>
      integer().check(amount.isBetweenValues(1, 999999999))();

  /// Compte débité (dépense, transfert) ou crédité (revenu).
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.cascade)();

  /// Compte crédité d'un transfert ; `NULL` sinon.
  TextColumn get toAccountId => text().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Catégorie ou sous-catégorie ; `NULL` uniquement pour un transfert.
  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get description => text().nullable().withLength(min: 1, max: 80)();

  IntColumn get occurredAt => integer()();

  /// Mode de saisie (valeurs de `EntryMethod.storageValue`).
  TextColumn get entryMethod => text()
      .withDefault(const Constant('manual'))
      .check(
        entryMethod.isIn(const [
          'manual',
          'voice',
          'text',
          'receipt',
          'recurring',
        ]),
      )();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  /// Un transfert relie deux comptes distincts sans catégorie ; une dépense ou
  /// un revenu a une catégorie et un seul compte.
  @override
  List<String> get customConstraints => [
    "CHECK ((kind = 'transfer' AND to_account_id IS NOT NULL "
        'AND to_account_id <> account_id AND category_id IS NULL) '
        "OR (kind <> 'transfer' AND to_account_id IS NULL "
        'AND category_id IS NOT NULL))',
  ];
}
