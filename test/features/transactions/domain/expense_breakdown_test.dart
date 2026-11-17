import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/core/money/percent_split.dart';
import 'package:finance_app/features/categories/domain/category.dart';
import 'package:finance_app/features/transactions/domain/expense_breakdown.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

Category _cat(String id) => Category(
  id: id,
  name: id,
  kind: CategoryKind.expense,
  iconKey: 'tag',
);

Transaction _tx(
  TransactionKind kind,
  int amount, {
  Category? category,
  Category? parent,
}) => Transaction(
  id: '$kind-$amount-${category?.id}',
  kind: kind,
  amount: Money(amount),
  accountId: 'wave',
  accountName: 'Wave',
  toAccountId: kind == TransactionKind.transfer ? 'eco' : null,
  category: category,
  parentCategory: parent,
  occurredAt: DateTime(2026, 11, 15),
  entryMethod: EntryMethod.manual,
);

void main() {
  test('dépenses par catégorie principale ; revenus et transferts ignorés', () {
    final food = _cat('Alimentation');
    final market = Category(
      id: 'market',
      name: 'Marché',
      kind: CategoryKind.expense,
      iconKey: 'basket',
      parentId: food.id,
    );
    final breakdown = ExpenseBreakdown.of([
      _tx(TransactionKind.expense, 6000, category: market, parent: food),
      _tx(TransactionKind.expense, 2000, category: food),
      _tx(TransactionKind.expense, 2000, category: _cat('Transport')),
      _tx(TransactionKind.income, 45000, category: _cat('Salaire')),
      _tx(TransactionKind.transfer, 25000),
    ]);

    expect(breakdown.total, const Money(10000));
    expect(
      breakdown.shares.map((s) => (s.category?.name, s.amount.value, s.percent)),
      [('Alimentation', 8000, 80), ('Transport', 2000, 20)],
    );
  });

  test('au-delà de 5 catégories, les plus petites forment « Autres »', () {
    final breakdown = ExpenseBreakdown.of([
      for (var i = 1; i <= 7; i++)
        _tx(TransactionKind.expense, i * 1000, category: _cat('C$i')),
    ]);

    expect(breakdown.shares, hasLength(ExpenseBreakdown.maxShares));
    expect(breakdown.shares.last.category, isNull);
    expect(breakdown.shares.last.amount, const Money(1000 + 2000 + 3000));
    expect(breakdown.shares.fold<int>(0, (s, e) => s + e.percent), 100);
  });

  test('sans dépense, la répartition est vide', () {
    expect(ExpenseBreakdown.of(const []).isEmpty, isTrue);
  });

  test('splitPercentages : somme à 100, total nul géré', () {
    expect(splitPercentages([1, 1, 1]), [34, 33, 33]);
    expect(splitPercentages([0, 0]), [0, 0]);
  });
}
