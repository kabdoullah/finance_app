import 'package:flutter/foundation.dart';

import '../../../core/money/money.dart';
import 'account_type.dart';

enum AccountFieldError {
  typeMissing,
  nameMissing,
  nameTooLong,

  /// Un autre compte actif porte déjà ce nom (vérifié par le repository).
  nameTaken,
  openingBalanceInvalid,
}

/// Saisie du formulaire de compte, avant validation.
@immutable
class AccountDraft {
  const AccountDraft({
    this.type,
    this.name = '',
    this.openingBalance = Money.zero,
  });

  static const maxNameLength = 40;
  static const maxOpeningBalance = Money(9999999999);

  static final _spaces = RegExp(r'\s+');

  final AccountType? type;
  final String name;
  final Money openingBalance;

  /// Nom enregistré : sans espaces autour ni espaces multiples.
  String get normalizedName => name.trim().replaceAll(_spaces, ' ');

  /// Règles qui ne dépendent pas des autres comptes.
  Set<AccountFieldError> validate() => {
    if (type == null) AccountFieldError.typeMissing,
    if (normalizedName.isEmpty) AccountFieldError.nameMissing,
    if (normalizedName.length > maxNameLength) AccountFieldError.nameTooLong,
    if (openingBalance.isNegative ||
        openingBalance.value > maxOpeningBalance.value)
      AccountFieldError.openingBalanceInvalid,
  };
}
