import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../../../core/money/percent_split.dart';
import '../../categories/domain/category.dart';
import 'transaction.dart';

/// Part d'une catégorie principale (ou du regroupement « Autres ») dans les
/// dépenses.
@immutable
class ExpenseShare {
  const ExpenseShare({
    required this.amount,
    required this.percent,
    this.category,
  });

  /// `null` pour le regroupement des plus petites catégories (« Autres »).
  final Category? category;
  final Money amount;

  /// Pourcentage entier ; la somme des parts vaut toujours 100.
  final int percent;
}

/// « Où va ton argent » : dépenses par catégorie principale, de la plus
/// grande à la plus petite. Les revenus et transferts sont ignorés.
@immutable
class ExpenseBreakdown {
  const ExpenseBreakdown._(this.total, this.shares);

  factory ExpenseBreakdown.of(Iterable<Transaction> transactions) {
    final byCategory = <String, (Category, int)>{};
    for (final t in transactions) {
      final category = t.mainCategory;
      if (t.kind != TransactionKind.expense || category == null) continue;
      final current = byCategory[category.id]?.$2 ?? 0;
      byCategory[category.id] = (category, current + t.amount.value);
    }

    final sorted = byCategory.values.toList()
      ..sort((a, b) {
        final byAmount = b.$2.compareTo(a.$2);
        return byAmount != 0 ? byAmount : a.$1.name.compareTo(b.$1.name);
      });

    // Au-delà de maxShares catégories, les plus petites sont regroupées.
    final kept = sorted.length > maxShares
        ? sorted.take(maxShares - 1).toList()
        : sorted;
    final others = sorted
        .skip(kept.length)
        .fold<int>(0, (sum, entry) => sum + entry.$2);
    final amounts = [
      for (final (_, amount) in kept) amount,
      if (others > 0) others,
    ];
    final percents = splitPercentages(amounts);

    return ExpenseBreakdown._(
      Money(amounts.fold<int>(0, (sum, a) => sum + a)),
      [
        for (var i = 0; i < amounts.length; i++)
          ExpenseShare(
            category: i < kept.length ? kept[i].$1 : null,
            amount: Money(amounts[i]),
            percent: percents[i],
          ),
      ],
    );
  }

  /// Nombre maximal de parts (une teinte de répartition par part).
  static const maxShares = 5;

  final Money total;
  final List<ExpenseShare> shares;

  bool get isEmpty => shares.isEmpty;
}
