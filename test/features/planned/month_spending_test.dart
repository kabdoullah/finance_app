import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/core/time/month.dart';
import 'package:finance_app/features/categories/domain/category.dart';
import 'package:finance_app/features/planned/domain/month_spending.dart';
import 'package:finance_app/features/planned/domain/planned_expense.dart';
import 'package:finance_app/features/recurring/domain/recurrence.dart';
import 'package:finance_app/features/recurring/domain/recurring_operation.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

const _education = Category(
  id: 'exp.education',
  name: 'Éducation',
  kind: CategoryKind.expense,
  iconKey: 'education',
);
const _housing = Category(
  id: 'exp.housing',
  name: 'Logement',
  kind: CategoryKind.expense,
  iconKey: 'housing',
);
const _food = Category(
  id: 'exp.food',
  name: 'Alimentation',
  kind: CategoryKind.expense,
  iconKey: 'food',
);

const _nov = Month(2026, 11);
const _dec = Month(2026, 12);

final _scolarite = PlannedExpense(
  id: 'scol',
  name: 'Scolarité',
  amount: const Money(150000),
  category: _education,
  accountId: 'eco',
  accountName: 'Ecobank',
  dueDate: DateTime(2026, 12, 15),
  createdAt: DateTime(2026, 11, 20),
);

Transaction _expense(
  String id,
  int amount,
  DateTime at, {
  Category category = _food,
  TransactionKind kind = TransactionKind.expense,
}) => Transaction(
  id: id,
  kind: kind,
  amount: Money(amount),
  accountId: 'eco',
  accountName: 'Ecobank',
  occurredAt: at,
  entryMethod: EntryMethod.manual,
  category: kind == TransactionKind.transfer ? null : category,
);

RecurringOperation _rent({
  DateTime? nextDue,
  bool paused = false,
  bool variable = false,
  TransactionKind kind = TransactionKind.expense,
}) => RecurringOperation(
  id: 'loyer',
  kind: kind,
  name: 'Loyer',
  amount: const Money(75000),
  isVariable: variable,
  category: _housing,
  accountId: 'eco',
  accountName: 'Ecobank',
  recurrence: Recurrence(
    frequency: RecurrenceFrequency.month,
    start: DateTime(2026, 9, 2),
  ),
  nextDue: nextDue ?? DateTime(2026, 12, 2),
  askBeforeRecording: true,
  isPaused: paused,
);

MonthSpending _month(
  Month month, {
  required DateTime now,
  List<Transaction> transactions = const [],
  List<PlannedExpense> planned = const [],
  List<RecurringOperation> recurring = const [],
}) => MonthSpending.of(
  month: month,
  transactions: transactions,
  dues: DueItem.collect(
    planned: planned,
    recurring: recurring,
    until: DateTime(2027, 12, 31),
  ),
  now: now,
);

void main() {
  final paidInNov = [
    _expense('t1', 22000, DateTime(2026, 11, 1, 10)),
    _expense('t2', 3000, DateTime(2026, 11, 3, 18)),
    // Transfert : jamais compté comme dépense.
    _expense(
      't3',
      25000,
      DateTime(2026, 11, 14),
      kind: TransactionKind.transfer,
    ),
  ];

  group('scénarios de la maquette (Regles-Planifiees)', () {
    test('A · créée le 20 nov. : décembre +150 000, novembre inchangé', () {
      final now = DateTime(2026, 11, 20, 10);
      final before = _month(_dec, now: now);
      final after = _month(_dec, now: now, planned: [_scolarite]);
      final nov = _month(
        _nov,
        now: now,
        transactions: paidInNov,
        planned: [_scolarite],
      );

      expect(after.planned.value - before.planned.value, 150000);
      expect(after.paid, Money.zero);
      expect(after.total, const Money(150000));
      expect(nov.paid, const Money(25000));
      expect(nov.planned, Money.zero);
    });

    test('B · payée le 25 nov. : payées de novembre +150 000, '
        'plus dans décembre', () {
      final now = DateTime(2026, 11, 25, 18);
      final paid = _expense(
        'scol',
        150000,
        DateTime(2026, 11, 25, 18),
        category: _education,
      );
      final nov = _month(_nov, now: now, transactions: [...paidInNov, paid]);
      final dec = _month(_dec, now: now);

      expect(nov.paid, const Money(25000 + 150000));
      expect(dec.planned, Money.zero);
      expect(nov.paidByCategory.first.$1, _education);
    });

    test('C · rien payé au 16 déc. : en retard, toujours planifiée '
        'en décembre, absente des payées', () {
      final now = DateTime(2026, 12, 16, 9);
      final dec = _month(_dec, now: now, planned: [_scolarite]);

      expect(dec.planned, const Money(150000));
      expect(dec.late, const Money(150000));
      expect(dec.paid, Money.zero);
      expect(dec.dues.single.statusOn(now), PlannedStatus.late);
    });

    test('D · calendrier : le 15 déc. porte une dépense à payer, '
        'sans dépense payée', () {
      final dec = _month(
        _dec,
        now: DateTime(2026, 11, 20),
        planned: [_scolarite],
      );

      expect(dec.duesOn(DateTime(2026, 12, 15)), hasLength(1));
      expect(dec.spentByDay[DateTime(2026, 12, 15)], isNull);
    });
  });

  group('échéances récurrentes', () {
    test('comptées à leur date, au mois de leur échéance', () {
      final now = DateTime(2026, 11, 20);
      final dec = _month(_dec, now: now, recurring: [_rent()]);
      final jan = _month(const Month(2027, 1), now: now, recurring: [_rent()]);

      expect(dec.dues.single.source, DueSource.recurring);
      expect(dec.dues.single.date, DateTime(2026, 12, 2));
      expect(dec.planned, const Money(75000));
      expect(jan.planned, const Money(75000));
    });

    test('« à confirmer » passée : en retard dans son mois', () {
      final now = DateTime(2026, 11, 20);
      final nov = _month(
        _nov,
        now: now,
        recurring: [_rent(nextDue: DateTime(2026, 11, 2))],
      );

      expect(nov.late, const Money(75000));
      expect(nov.dues.single.statusOn(now), PlannedStatus.late);
    });

    test('revenus et modèles en pause exclus ; montant variable estimé', () {
      final now = DateTime(2026, 11, 20);
      expect(
        _month(_dec, now: now, recurring: [_rent(paused: true)]).dues,
        isEmpty,
      );
      expect(
        _month(
          _dec,
          now: now,
          recurring: [_rent(kind: TransactionKind.income)],
        ).dues,
        isEmpty,
      );
      expect(
        _month(
          _dec,
          now: now,
          recurring: [_rent(variable: true)],
        ).dues.single.isEstimate,
        isTrue,
      );
    });
  });

  test('mois budgétaire décalé : du 25 oct. au 24 nov.', () {
    const shifted = Month(2026, 11, startDay: 25);
    final spending = _month(
      shifted,
      now: DateTime(2026, 11, 20),
      transactions: [
        _expense('a', 1000, DateTime(2026, 10, 26)),
        _expense('b', 2000, DateTime(2026, 11, 25)),
      ],
    );

    expect(spending.paid, const Money(1000));
  });

  test('intensité : moins de 5 000, moins de 20 000, au-delà', () {
    expect(MonthSpending.intensity(0), 0);
    expect(MonthSpending.intensity(4999), 1);
    expect(MonthSpending.intensity(5000), 2);
    expect(MonthSpending.intensity(19999), 2);
    expect(MonthSpending.intensity(20000), 3);
  });
}
