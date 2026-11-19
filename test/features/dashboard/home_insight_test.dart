import 'dart:ui' show Locale;

import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/core/time/month.dart';
import 'package:finance_app/features/budgets/domain/budget.dart';
import 'package:finance_app/features/categories/domain/category.dart';
import 'package:finance_app/features/dashboard/domain/home_insight.dart';
import 'package:finance_app/features/recurring/domain/recurrence.dart';
import 'package:finance_app/features/recurring/domain/recurring_operation.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _now = DateTime(2026, 11, 15, 10);
const _month = Month(2026, 11);
final _l10n = lookupAppLocalizations(const Locale('fr'));

const _transport = Category(
  id: 'exp.transport',
  name: 'Transport',
  kind: CategoryKind.expense,
  iconKey: 'bus',
);
const _taxi = Category(
  id: 'exp.transport.taxi',
  name: 'Taxi',
  kind: CategoryKind.expense,
  iconKey: 'taxi',
  parentId: 'exp.transport',
);

Transaction _expense(int amount, DateTime at, {Category? category}) =>
    Transaction(
      id: '$amount-$at',
      kind: TransactionKind.expense,
      amount: Money(amount),
      accountId: 'w',
      accountName: 'Wave',
      category: category ?? _taxi,
      parentCategory: (category ?? _taxi).parentId == null ? null : _transport,
      occurredAt: at,
      entryMethod: EntryMethod.manual,
    );

BudgetsOverview _budgets(List<Transaction> month) => BudgetsOverview.of(
  budgets: const [
    Budget(
      id: 'b',
      category: _transport,
      limit: Money(30000),
      alertPercent: 80,
    ),
  ],
  monthTransactions: month,
  expenseCategories: const [_transport],
  now: _now,
  month: _month,
);

PendingOccurrence _pending() => PendingOccurrence(
  RecurringOperation(
    id: 'r',
    kind: TransactionKind.expense,
    name: 'Loyer',
    amount: const Money(75000),
    isVariable: false,
    category: _transport,
    accountId: 'w',
    accountName: 'Wave',
    recurrence: Recurrence(
      frequency: RecurrenceFrequency.month,
      start: DateTime(2026, 1, 14),
    ),
    nextDue: DateTime(2026, 11, 14),
    askBeforeRecording: true,
    isPaused: false,
  ),
  DateTime(2026, 11, 14),
  isFirst: true,
);

HomeInsight? _pick({
  List<Transaction> month = const [],
  List<Transaction> previous = const [],
  List<PendingOccurrence> pending = const [],
  bool withBudget = true,
}) => HomeInsights.pick(
  budgets: withBudget ? _budgets(month) : null,
  forecast: null,
  pending: pending,
  currentMonth: month,
  previousMonth: previous,
  month: _month,
  now: _now,
  l10n: _l10n,
);

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  test('budget dépassé, avec sa cause : priorité absolue', () {
    final insight = _pick(
      month: [
        for (var d = 1; d <= 11; d++) _expense(3000, DateTime(2026, 11, d)),
      ],
      pending: [_pending()],
    );
    expect(
      insight?.text,
      'Ton budget Transport est dépassé de 3 000 FCFA, surtout à cause '
      'de Taxi (11 opérations).',
    );
    expect(insight?.question, 'Pourquoi mon budget Transport est dépassé ?');
  });

  test('seuil d\'alerte : reste et jours restants', () {
    final insight = _pick(month: [_expense(25000, DateTime(2026, 11, 3))]);
    expect(
      insight?.text,
      'Ton budget Transport est utilisé à 83 % : il te reste 5 000 FCFA '
      'pour 16 jours.',
    );
    expect(insight?.question, 'Combien puis-je dépenser cette semaine ?');
  });

  test('échéance à confirmer : pas de question, lien vers l\'échéance', () {
    final insight = _pick(pending: [_pending()]);
    expect(insight?.text, 'Loyer (75 000 FCFA) attend ta confirmation.');
    expect(insight?.question, isNull);
  });

  test('dépenses en hausse par rapport au mois dernier, même date', () {
    final insight = _pick(
      withBudget: false,
      month: [_expense(30000, DateTime(2026, 11, 10))],
      previous: [
        _expense(20000, DateTime(2026, 10, 5)),
        // Après le 15 oct. : hors comparaison.
        _expense(50000, DateTime(2026, 10, 20)),
      ],
    );
    expect(
      insight?.text,
      'Tu as dépensé 50 % de plus que le mois dernier à la même date : '
      '30 000 FCFA contre 20 000 FCFA.',
    );
  });

  test('rien à signaler', () {
    expect(_pick(month: [_expense(1000, DateTime(2026, 11, 3))]), isNull);
    // Hausse trop faible en montant.
    expect(
      _pick(
        withBudget: false,
        month: [_expense(3000, DateTime(2026, 11, 3))],
        previous: [_expense(1000, DateTime(2026, 10, 3))],
      ),
      isNull,
    );
  });
}
