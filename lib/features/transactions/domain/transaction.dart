import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../../categories/domain/category.dart';

enum TransactionKind {
  expense('expense'),
  income('income'),
  transfer('transfer');

  const TransactionKind(this.storageValue);

  final String storageValue;

  static TransactionKind fromStorage(String value) =>
      values.firstWhere((kind) => kind.storageValue == value);

  /// Type de catégorie attendu ; `null` pour un transfert (sans catégorie).
  CategoryKind? get categoryKind => switch (this) {
    TransactionKind.expense => CategoryKind.expense,
    TransactionKind.income => CategoryKind.income,
    TransactionKind.transfer => null,
  };
}

/// Comment l'opération a été saisie (ligne « Saisie » du détail).
enum EntryMethod {
  manual('manual'),
  voice('voice'),
  text('text'),
  receipt('receipt'),
  recurring('recurring');

  const EntryMethod(this.storageValue);

  final String storageValue;

  static EntryMethod fromStorage(String value) =>
      values.firstWhere((method) => method.storageValue == value);
}

/// Opération enregistrée, avec les libellés utiles à l'affichage.
@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.kind,
    required this.amount,
    required this.accountId,
    required this.accountName,
    required this.occurredAt,
    required this.entryMethod,
    this.toAccountId,
    this.toAccountName,
    this.category,
    this.parentCategory,
    this.description,
    this.recurringId,
  });

  final String id;
  final TransactionKind kind;

  /// Toujours positif ; le sens dépend de [kind].
  final Money amount;

  /// Compte débité (dépense, transfert) ou crédité (revenu).
  final String accountId;
  final String accountName;

  /// Compte crédité d'un transfert.
  final String? toAccountId;
  final String? toAccountName;

  /// Catégorie ou sous-catégorie choisie (`null` pour un transfert).
  final Category? category;

  /// Catégorie principale quand [category] est une sous-catégorie.
  final Category? parentCategory;

  final String? description;
  final DateTime occurredAt;
  final EntryMethod entryMethod;

  /// Modèle récurrent qui a produit l'opération, s'il existe encore.
  final String? recurringId;

  /// Catégorie principale (celle qui compte pour les budgets).
  Category? get mainCategory => parentCategory ?? category;

  bool get isTransfer => kind == TransactionKind.transfer;

  bool involves(String id) => accountId == id || toAccountId == id;

  /// Effet de l'opération sur le solde du compte [id] (0 s'il n'est pas
  /// concerné).
  Money effectOn(String id) {
    if (kind == TransactionKind.transfer) {
      if (toAccountId == id) return amount;
      if (accountId == id) return -amount;
      return Money.zero;
    }
    if (accountId != id) return Money.zero;
    return kind == TransactionKind.income ? amount : -amount;
  }
}
