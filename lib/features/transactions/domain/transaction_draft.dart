import 'package:flutter/foundation.dart';

import '../../../core/money/money.dart';
import 'transaction.dart';

enum TransactionFieldError {
  amountMissing,
  amountTooLarge,
  accountMissing,

  /// Compte inexistant ou archivé (vérifié par le repository).
  accountUnavailable,
  toAccountMissing,
  sameAccount,
  categoryMissing,

  /// Catégorie inexistante ou d'un autre type (vérifié par le repository).
  categoryInvalid,
  descriptionTooLong,
}

/// Saisie d'une opération, avant validation.
@immutable
class TransactionDraft {
  const TransactionDraft({
    required this.kind,
    required this.amount,
    required this.occurredAt,
    this.accountId,
    this.toAccountId,
    this.categoryId,
    this.description = '',
  });

  /// Brouillon reprenant une opération existante (modification, duplication).
  factory TransactionDraft.from(Transaction transaction) => TransactionDraft(
    kind: transaction.kind,
    amount: transaction.amount,
    occurredAt: transaction.occurredAt,
    accountId: transaction.accountId,
    toAccountId: transaction.toAccountId,
    categoryId: transaction.category?.id,
    description: transaction.description ?? '',
  );

  /// 9 chiffres, comme le clavier de saisie.
  static const maxAmount = Money(999999999);
  static const maxDescriptionLength = 80;

  static final _spaces = RegExp(r'\s+');

  final TransactionKind kind;
  final Money amount;
  final DateTime occurredAt;
  final String? accountId;
  final String? toAccountId;
  final String? categoryId;
  final String description;

  /// Description enregistrée, ou `null` si vide.
  String? get normalizedDescription {
    final text = description.trim().replaceAll(_spaces, ' ');
    return text.isEmpty ? null : text;
  }

  TransactionDraft copyWith({
    TransactionKind? kind,
    Money? amount,
    DateTime? occurredAt,
    String? accountId,
    String? toAccountId,
    String? categoryId,
    String? description,
  }) => TransactionDraft(
    kind: kind ?? this.kind,
    amount: amount ?? this.amount,
    occurredAt: occurredAt ?? this.occurredAt,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId ?? this.toAccountId,
    categoryId: categoryId ?? this.categoryId,
    description: description ?? this.description,
  );

  /// Règles qui ne dépendent pas de la base.
  Set<TransactionFieldError> validate() {
    final isTransfer = kind == TransactionKind.transfer;
    return {
      if (amount.value <= 0) TransactionFieldError.amountMissing,
      if (amount.value > maxAmount.value) TransactionFieldError.amountTooLarge,
      if (accountId == null) TransactionFieldError.accountMissing,
      if (isTransfer && toAccountId == null)
        TransactionFieldError.toAccountMissing,
      if (isTransfer && accountId != null && toAccountId == accountId)
        TransactionFieldError.sameAccount,
      if (!isTransfer && categoryId == null)
        TransactionFieldError.categoryMissing,
      if ((normalizedDescription?.length ?? 0) > maxDescriptionLength)
        TransactionFieldError.descriptionTooLong,
    };
  }
}
