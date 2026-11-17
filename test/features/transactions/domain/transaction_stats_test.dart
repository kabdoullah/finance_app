import 'package:finance_app/core/formatting/text_search.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/core/time/month.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/features/transactions/domain/transaction_draft.dart';
import 'package:finance_app/features/transactions/domain/transaction_stats.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _tx(
  String id,
  TransactionKind kind,
  int amount, {
  String account = 'wave',
  String? to,
  DateTime? at,
}) => Transaction(
  id: id,
  kind: kind,
  amount: Money(amount),
  accountId: account,
  accountName: account,
  toAccountId: to,
  toAccountName: to,
  occurredAt: at ?? DateTime(2026, 11, 15),
  entryMethod: EntryMethod.manual,
);

void main() {
  test('les totaux excluent les transferts', () {
    final totals = TransactionTotals.of([
      _tx('1', TransactionKind.income, 45000),
      _tx('2', TransactionKind.expense, 2500),
      _tx('3', TransactionKind.transfer, 25000, to: 'eco'),
    ]);

    expect(totals.income, const Money(45000));
    expect(totals.expense, const Money(2500));
  });

  test('flux mensuel d’un compte, transferts compris mais identifiés', () {
    final flow = AccountMonthFlow.of(
      [
        _tx('1', TransactionKind.transfer, 25000, account: 'eco', to: 'wave'),
        _tx('2', TransactionKind.expense, 2500),
        _tx('3', TransactionKind.expense, 9999, at: DateTime(2026, 10, 31)),
        _tx('4', TransactionKind.expense, 700, account: 'eco'),
      ],
      'wave',
      const Month(2026, 11),
    );

    expect(flow.incoming, const Money(25000));
    expect(flow.outgoing, const Money(2500));
    expect(flow.transfers, const Money(25000));
  });

  test('soldes successifs dans l’ordre chronologique', () {
    final balances = runningBalances(const Money(15000), [
      _tx('b', TransactionKind.expense, 2500, at: DateTime(2026, 11, 15)),
      _tx('a', TransactionKind.income, 30000, at: DateTime(2026, 11, 1)),
    ], 'wave');

    expect(balances, {'a': const Money(45000), 'b': const Money(42500)});
  });

  test('brouillon : montant, compte, catégorie et transfert', () {
    final draft = TransactionDraft(
      kind: TransactionKind.transfer,
      amount: Money.zero,
      occurredAt: DateTime(2026, 11, 15),
      accountId: 'wave',
      toAccountId: 'wave',
      description: '  ',
    );

    expect(draft.validate(), {
      TransactionFieldError.amountMissing,
      TransactionFieldError.sameAccount,
    });
    expect(draft.normalizedDescription, isNull);
  });

  test('Month : bornes, mois précédent et suivant', () {
    const january = Month(2027, 1);

    expect(january.previous, const Month(2026, 12));
    expect(const Month(2026, 12).next, january);
    expect(january.contains(DateTime(2027, 1, 31, 23, 59)), isTrue);
    expect(january.contains(DateTime(2027, 2)), isFalse);
  });

  test('recherche sans casse ni accents', () {
    expect(TextSearch.matches('electricite', ['Factures', 'Électricité']), isTrue);
    expect(TextSearch.matches('WÔRÔ', ['Wôrô-wôrô']), isTrue);
    expect(TextSearch.matches('boulangerie', ['Taxi', null]), isFalse);
    expect(TextSearch.matches('  ', ['Taxi']), isTrue);
  });
}
