import 'package:flutter/foundation.dart';

import '../../../core/money/money.dart';
import 'account.dart';
import 'account_type.dart';

/// Part d'un compte (ou du regroupement « Autres ») dans le total.
@immutable
class AccountShare {
  const AccountShare({
    required this.amount,
    required this.percent,
    this.account,
  });

  /// `null` pour le regroupement des plus petits comptes (« Autres »).
  final Account? account;
  final Money amount;

  /// Pourcentage entier ; la somme des parts vaut toujours 100.
  final int percent;
}

/// Vue d'ensemble des comptes actifs : total, sous-totaux par type et
/// répartition. Calcul déterministe, indépendant de l'interface.
@immutable
class AccountsSummary {
  const AccountsSummary._({
    required this.total,
    required this.count,
    required this.subtotals,
    required this.shares,
  });

  factory AccountsSummary.of(Iterable<Account> accounts) {
    final active = accounts.where((a) => !a.isArchived).toList();

    var total = Money.zero;
    final subtotals = <AccountType, Money>{};
    for (final account in active) {
      total += account.balance;
      subtotals[account.type] =
          (subtotals[account.type] ?? Money.zero) + account.balance;
    }

    return AccountsSummary._(
      total: total,
      count: active.length,
      subtotals: subtotals,
      shares: _shares(active),
    );
  }

  /// Nombre maximal de parts affichées (une teinte de répartition par part).
  static const maxShares = 5;

  final Money total;
  final int count;

  /// Sous-total par type, uniquement pour les types qui ont un compte actif.
  final Map<AccountType, Money> subtotals;

  /// Répartition des soldes positifs, de la plus grande à la plus petite part.
  final List<AccountShare> shares;

  static List<AccountShare> _shares(List<Account> active) {
    final positive = active.where((a) => a.balance.value > 0).toList()
      ..sort((a, b) {
        final byBalance = b.balance.value.compareTo(a.balance.value);
        return byBalance != 0 ? byBalance : a.name.compareTo(b.name);
      });
    if (positive.isEmpty) return const [];

    // Au-delà de maxShares comptes, les plus petits sont regroupés.
    final kept = positive.length > maxShares
        ? positive.take(maxShares - 1).toList()
        : positive;
    final others = positive.skip(kept.length).fold<int>(
      0,
      (sum, a) => sum + a.balance.value,
    );
    final amounts = [
      for (final a in kept) a.balance.value,
      if (others > 0) others,
    ];
    final percents = _largestRemainder(amounts);

    return [
      for (var i = 0; i < amounts.length; i++)
        AccountShare(
          account: i < kept.length ? kept[i] : null,
          amount: Money(amounts[i]),
          percent: percents[i],
        ),
    ];
  }

  /// Pourcentages entiers dont la somme vaut exactement 100 (méthode du plus
  /// fort reste ; à reste égal, la plus grande part l'emporte).
  static List<int> _largestRemainder(List<int> amounts) {
    final total = amounts.fold<int>(0, (sum, a) => sum + a);
    final floors = [for (final a in amounts) a * 100 ~/ total];
    final remainders = [for (final a in amounts) a * 100 % total];

    final order = List<int>.generate(amounts.length, (i) => i)
      ..sort((i, j) {
        final byRemainder = remainders[j].compareTo(remainders[i]);
        return byRemainder != 0 ? byRemainder : i.compareTo(j);
      });
    var missing = 100 - floors.fold<int>(0, (sum, p) => sum + p);
    for (final i in order) {
      if (missing == 0) break;
      floors[i]++;
      missing--;
    }
    return floors;
  }
}
