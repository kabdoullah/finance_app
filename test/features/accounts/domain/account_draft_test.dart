import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un brouillon complet est valide', () {
    const draft = AccountDraft(
      type: AccountType.mobileMoney,
      name: 'Wave',
      openingBalance: Money(15000),
    );

    expect(draft.validate(), isEmpty);
  });

  test('type et nom sont requis', () {
    expect(const AccountDraft(name: '   ').validate(), {
      AccountFieldError.typeMissing,
      AccountFieldError.nameMissing,
    });
  });

  test('le nom est normalisé (espaces) et limité à 40 caractères', () {
    expect(
      const AccountDraft(name: '  Tontine   du  quartier ').normalizedName,
      'Tontine du quartier',
    );
    expect(
      AccountDraft(type: AccountType.savings, name: 'x' * 41).validate(),
      {AccountFieldError.nameTooLong},
    );
  });

  test('le solde initial est compris entre 0 et 9 999 999 999', () {
    const base = AccountDraft(type: AccountType.cash, name: 'Portefeuille');

    expect(
      const AccountDraft(
        type: AccountType.cash,
        name: 'Portefeuille',
        openingBalance: Money(-1),
      ).validate(),
      {AccountFieldError.openingBalanceInvalid},
    );
    expect(
      const AccountDraft(
        type: AccountType.cash,
        name: 'Portefeuille',
        openingBalance: Money(10000000000),
      ).validate(),
      {AccountFieldError.openingBalanceInvalid},
    );
    expect(base.validate(), isEmpty);
  });
}
