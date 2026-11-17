import 'package:flutter/foundation.dart';

import '../../../core/money/money.dart';
import '../../../core/time/month.dart';
import 'transaction.dart';

/// Revenus et dépenses d'une liste d'opérations. Les transferts sont exclus :
/// déplacer de l'argent entre ses comptes n'est ni un revenu ni une dépense.
@immutable
class TransactionTotals {
  const TransactionTotals({required this.income, required this.expense});

  factory TransactionTotals.of(Iterable<Transaction> transactions) {
    var income = Money.zero;
    var expense = Money.zero;
    for (final t in transactions) {
      switch (t.kind) {
        case TransactionKind.income:
          income += t.amount;
        case TransactionKind.expense:
          expense += t.amount;
        case TransactionKind.transfer:
          break;
      }
    }
    return TransactionTotals(income: income, expense: expense);
  }

  final Money income;
  final Money expense;
}

/// Entrées et sorties d'un compte sur un mois (transferts compris), avec la
/// part due aux transferts, exclue des revenus et dépenses.
@immutable
class AccountMonthFlow {
  const AccountMonthFlow({
    required this.incoming,
    required this.outgoing,
    required this.transfers,
  });

  factory AccountMonthFlow.of(
    Iterable<Transaction> transactions,
    String accountId,
    Month month,
  ) {
    var incoming = Money.zero;
    var outgoing = Money.zero;
    var transfers = Money.zero;
    for (final t in transactions) {
      if (!month.contains(t.occurredAt)) continue;
      final effect = t.effectOn(accountId);
      if (effect.value == 0) continue;
      if (effect.isNegative) {
        outgoing += -effect;
      } else {
        incoming += effect;
      }
      if (t.isTransfer) transfers += t.amount;
    }
    return AccountMonthFlow(
      incoming: incoming,
      outgoing: outgoing,
      transfers: transfers,
    );
  }

  final Money incoming;

  /// Montant positif.
  final Money outgoing;
  final Money transfers;
}

/// Solde du compte [accountId] juste après chaque opération (« Solde après »).
///
/// [transactions] : toutes les opérations du compte, dans n'importe quel
/// ordre. L'ordre chronologique est celui de `occurredAt`, puis de l'id.
Map<String, Money> runningBalances(
  Money openingBalance,
  Iterable<Transaction> transactions,
  String accountId,
) {
  final sorted = transactions.where((t) => t.involves(accountId)).toList()
    ..sort((a, b) {
      final byDate = a.occurredAt.compareTo(b.occurredAt);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
  var balance = openingBalance;
  return {for (final t in sorted) t.id: balance += t.effectOn(accountId)};
}
