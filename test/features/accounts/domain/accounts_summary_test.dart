import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/domain/account.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/accounts/domain/accounts_summary.dart';
import 'package:flutter_test/flutter_test.dart';

Account _account(
  String name,
  int balance, {
  AccountType type = AccountType.mobileMoney,
  bool archived = false,
}) => Account(
  id: name,
  name: name,
  type: type,
  openingBalance: Money(balance),
  balance: Money(balance),
  createdAt: DateTime.utc(2026, 11, 1),
  archivedAt: archived ? DateTime.utc(2026, 11, 2) : null,
);

void main() {
  test('total, nombre et sous-totaux ignorent les comptes archivés', () {
    final summary = AccountsSummary.of([
      _account('Wave', 42000),
      _account('Orange Money', 31000),
      _account('Ecobank', 126000, type: AccountType.bank),
      _account('MTN MoMo', 9000, archived: true),
    ]);

    expect(summary.total, const Money(199000));
    expect(summary.count, 3);
    expect(summary.subtotals, {
      AccountType.mobileMoney: const Money(73000),
      AccountType.bank: const Money(126000),
    });
  });

  test('répartition triée, pourcentages entiers dont la somme vaut 100', () {
    // Exemple des maquettes : 58 / 19 / 14 / 9.
    final summary = AccountsSummary.of([
      _account('Wave', 42000),
      _account('Orange Money', 31000),
      _account('Ecobank', 126000, type: AccountType.bank),
      _account('Portefeuille', 18500, type: AccountType.cash),
    ]);

    expect(
      summary.shares.map((s) => (s.account?.name, s.percent)),
      [('Ecobank', 58), ('Wave', 19), ('Orange Money', 14), ('Portefeuille', 9)],
    );
  });

  test('le plus fort reste complète à 100 (3 tiers)', () {
    final summary = AccountsSummary.of([
      _account('A', 1000),
      _account('B', 1000),
      _account('C', 1000),
    ]);

    expect(summary.shares.map((s) => s.percent), [34, 33, 33]);
  });

  test('au-delà de 5 comptes, les plus petits sont regroupés', () {
    final summary = AccountsSummary.of([
      for (var i = 1; i <= 7; i++) _account('Compte $i', i * 1000),
    ]);

    expect(summary.shares, hasLength(AccountsSummary.maxShares));
    final others = summary.shares.last;
    expect(others.account, isNull);
    expect(others.amount, const Money(1000 + 2000 + 3000));
    expect(summary.shares.fold<int>(0, (sum, s) => sum + s.percent), 100);
  });

  test('aucune part quand aucun solde n’est positif', () {
    final summary = AccountsSummary.of([_account('Wave', 0)]);

    expect(summary.total, Money.zero);
    expect(summary.shares, isEmpty);
  });
}
