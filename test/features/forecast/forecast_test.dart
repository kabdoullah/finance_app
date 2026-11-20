import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/categories/domain/category.dart';
import 'package:finance_app/features/forecast/domain/forecast.dart';
import 'package:finance_app/features/forecast/domain/purchase_simulation.dart';
import 'package:finance_app/features/planned/domain/planned_expense.dart';
import 'package:finance_app/features/recurring/domain/recurrence.dart';
import 'package:finance_app/features/recurring/domain/recurring_operation.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 15, 9);

/// Historique de [days] jours, [perDay] FCFA de dépenses variables par jour.
SpendingHistory _history({int perDay = 8000, int days = 30}) => SpendingHistory(
  firstDay: DateTime(2026, 11, 15 - days + 1),
  variableExpenseByDay: {
    for (var k = 0; k < days; k++) DateTime(2026, 11, 15 - k): perDay,
  },
  netByDay: {for (var k = 0; k < 14; k++) DateTime(2026, 11, 15 - k): -perDay},
);

RecurringOperation _op(
  String name,
  int amount,
  DateTime nextDue, {
  TransactionKind kind = TransactionKind.expense,
}) => RecurringOperation(
  id: name,
  kind: kind,
  name: name,
  amount: Money(amount),
  isVariable: false,
  category: const Category(
    id: 'c',
    name: 'c',
    kind: CategoryKind.expense,
    iconKey: 'tag',
  ),
  accountId: 'a',
  accountName: 'Wave',
  recurrence: Recurrence(
    frequency: RecurrenceFrequency.month,
    start: DateTime(2026, 1, nextDue.day),
  ),
  nextDue: nextDue,
  askBeforeRecording: true,
  isPaused: false,
);

Forecast _compute({
  ForecastHorizon horizon = ForecastHorizon.month,
  int balance = 217500,
  SpendingHistory? history,
  List<RecurringOperation> recurring = const [],
  List<PlannedExpense> planned = const [],
}) => Forecast.compute(
  now: _now,
  horizon: horizon,
  balance: Money(balance),
  history: history ?? _history(),
  recurring: recurring,
  planned: planned,
);

RecurringOperation _salary() =>
    _op('Salaire', 380000, DateTime(2026, 12), kind: TransactionKind.income);

void main() {
  test('dépenses variables moyennes et courbe sans récurrentes', () {
    final f = _compute(horizon: ForecastHorizon.week);
    expect(f.dailyVariable, const Money(8000));
    expect(f.points.first, const Money(217500));
    expect(f.points.last, const Money(217500 - 7 * 8000));
    // Dépenses régulières : écart type nul, fourchette resserrée.
    expect(f.endRange, (const Money(160000), const Money(160000)));
    expect(f.expectedExpenses, const Money(56000));
  });

  test('récurrentes à leur date ; échéance en retard comptée aujourd’hui', () {
    final f = _compute(
      recurring: [
        _salary(),
        _op('Loyer', 75000, DateTime(2026, 12, 2)),
        // Échéance du 14 nov. pas encore confirmée.
        _op('Salle de sport', 10000, DateTime(2026, 11, 14)),
      ],
    );
    expect(f.events.map((e) => (e.name, e.date.day)), [
      ('Salle de sport', 15),
      ('Salaire', 1),
      ('Loyer', 2),
      // L'échéance suivante revient le 14 déc., dans l'horizon de 30 jours.
      ('Salle de sport', 14),
    ]);
    expect(f.expectedIncome, const Money(380000));
    // Le 2 déc. (j+17) : 217 500 − 17 × 8 000 − 10 000 + 380 000 − 75 000.
    expect(f.points[17], const Money(376500));
  });

  test('solde négatif possible : premier jour sous zéro', () {
    final f = _compute(balance: 30000);
    // 30 000 − 4 × 8 000 = −2 000 le 19 nov.
    expect(f.negativeOn, DateTime(2026, 11, 19));
    expect(f.lowBalance, isNull);
  });

  test('solde bas juste avant le salaire', () {
    // Minimum le 30 nov. : 180 000 − 15 × 8 000 = 60 000, au-dessus du
    // seuil de 7 jours de dépenses (56 000).
    expect(
      _compute(balance: 180000, recurring: [_salary()]).lowBalance,
      isNull,
    );

    final tight = _compute(balance: 150000, recurring: [_salary()]);
    // 150 000 − 15 × 8 000 = 30 000 < 56 000, la veille du salaire.
    expect(tight.lowBalance?.date, DateTime(2026, 11, 30));
    expect(tight.lowBalance?.balance, const Money(30000));
    expect(tight.lowBalance?.beforeIncome, isTrue);
  });

  test('fiabilité selon l’horizon, un cran plus bas sous 30 jours', () {
    expect(
      _compute(horizon: ForecastHorizon.week).reliability,
      ForecastReliability.high,
    );
    expect(
      _compute(horizon: ForecastHorizon.quarter).reliability,
      ForecastReliability.low,
    );
    expect(
      _compute(history: _history(days: 20)).reliability,
      ForecastReliability.low,
    );
  });

  test('passé : solde en fin de journée sur 14 jours', () {
    final f = _compute();
    expect(f.history, hasLength(15));
    expect(f.history.last, const Money(217500));
    // La veille au soir, il y avait 8 000 de plus.
    expect(f.history[13], const Money(225500));
  });

  test('jours d’historique', () {
    expect(SpendingHistory.empty.daysOfHistory(_now), 0);
    expect(_history(days: 6).daysOfHistory(_now), 6);
  });

  group('PurchaseSimulation', () {
    // 217 500, 8 000 par jour, salaire de 380 000 le 1er déc. (j+16),
    // 60 000 réservés aux objectifs.
    PurchaseSimulation simulate(int price, {int day = 0, int savings = 0}) =>
        PurchaseSimulation.compute(
          forecast: _compute(recurring: [_salary()]),
          reserved: const Money(60000),
          price: Money(price),
          purchaseDay: day,
          savingsUsed: Money(savings),
        );

    test('aujourd’hui : le disponible passe sous zéro dès demain', () {
      final s = simulate(150000);
      expect(s.verdict, PurchaseVerdict.discouraged);
      // 217 500 − 60 000 − 150 000 − 8 000 = −500 le 16 nov.
      expect(s.negativeOn, DateTime(2026, 11, 16));
      // Sans achat : 217 500 − 30 × 8 000 + 380 000 − 60 000 = 297 500.
      expect(s.endWithout, const Money(298000));
    });

    test('après le salaire : possible, ou serré si la marge est faible', () {
      final after = simulate(150000, day: 16);
      expect(after.verdict, PurchaseVerdict.possible);
      expect(after.lowest, const Money(148000));
      expect(after.lowestDate, DateTime(2026, 12, 15));

      // 297 500 − 250 000 = 47 500 < 7 jours de dépenses (56 000).
      expect(simulate(250000, day: 16).verdict, PurchaseVerdict.tight);
    });

    test('l’épargne utilisée réduit le coût de l’achat', () {
      // Coût 90 000 au lieu de 150 000 : 297 500 − 90 000 = 207 500.
      expect(simulate(150000, savings: 60000).endBalance, const Money(208000));
    });
  });

  group('dépenses planifiées (scénarios de la maquette)', () {
    PlannedExpense scolarite() => PlannedExpense(
      id: 'scol',
      name: 'Scolarité',
      amount: const Money(150000),
      category: const Category(
        id: 'exp.education',
        name: 'Éducation',
        kind: CategoryKind.expense,
        iconKey: 'education',
      ),
      accountId: 'a',
      accountName: 'Ecobank',
      dueDate: DateTime(2026, 12, 15),
      createdAt: DateTime(2026, 11, 15),
    );

    test('A · comptée à sa date prévue, solde actuel inchangé', () {
      final base = _compute();
      final withPlanned = _compute(planned: [scolarite()]);

      expect(withPlanned.points.first, base.points.first);
      // 15 nov. + 29 jours = 14 déc. : pas encore sortie.
      expect(withPlanned.points[29], base.points[29]);
      expect(withPlanned.points[30], Money(base.points[30].value - 150000));
      expect(withPlanned.events.single.isPlanned, isTrue);
    });

    test('B/E · payée en avance : prévision du 15 déc. identique', () {
      final planned = _compute(planned: [scolarite()]);
      // Payée : le solde baisse maintenant et la sortie prévue disparaît ;
      // la moyenne des dépenses courantes n'en tient pas compte.
      final paid = _compute(balance: 217500 - 150000);

      expect(paid.points.last, planned.points.last);
    });

    test('C · en retard : toujours à payer, comptée dès demain', () {
      Forecast at16Dec(List<PlannedExpense> planned) => Forecast.compute(
        now: DateTime(2026, 12, 16, 9),
        horizon: ForecastHorizon.week,
        balance: const Money(217500),
        history: _history(),
        recurring: const [],
        planned: planned,
      );
      final late = at16Dec([scolarite()]);
      final without = at16Dec(const []);

      expect(late.events.single.date, DateTime(2026, 12, 16));
      expect(late.points.first, without.points.first);
      expect(late.points[1], Money(without.points[1].value - 150000));
    });

    test('au-delà de l’horizon : pas encore comptée', () {
      final week = _compute(
        horizon: ForecastHorizon.week,
        planned: [scolarite()],
      );

      expect(week.events, isEmpty);
    });
  });
}
