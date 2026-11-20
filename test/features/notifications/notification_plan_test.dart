import 'dart:ui' show Locale;

import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/budgets/domain/budget.dart';
import 'package:finance_app/features/categories/domain/category.dart';
import 'package:finance_app/features/forecast/domain/forecast.dart';
import 'package:finance_app/features/notifications/domain/notification_plan.dart';
import 'package:finance_app/features/recurring/domain/recurrence.dart';
import 'package:finance_app/features/recurring/domain/recurring_operation.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _now = DateTime(2026, 11, 15, 10);
final _l10n = lookupAppLocalizations(const Locale('fr'));

const _food = Category(
  id: 'exp.food',
  name: 'Alimentation',
  kind: CategoryKind.expense,
  iconKey: 'basket',
);

RecurringOperation _op(
  String name,
  int amount,
  DateTime nextDue, {
  TransactionKind kind = TransactionKind.expense,
  bool ask = true,
  bool paused = false,
}) => RecurringOperation(
  id: name,
  kind: kind,
  name: name,
  amount: Money(amount),
  isVariable: false,
  category: _food,
  accountId: 'a',
  accountName: 'Wave',
  recurrence: Recurrence(
    frequency: RecurrenceFrequency.month,
    start: DateTime(2026, 1, nextDue.day),
  ),
  nextDue: nextDue,
  askBeforeRecording: ask,
  isPaused: paused,
);

Transaction _expense(int amount) => Transaction(
  id: 't$amount',
  kind: TransactionKind.expense,
  amount: Money(amount),
  accountId: 'a',
  accountName: 'Wave',
  category: _food,
  occurredAt: DateTime(2026, 11, 10),
  entryMethod: EntryMethod.manual,
);

BudgetsOverview _overview(int spent, {int limit = 50000}) => BudgetsOverview.of(
  budgets: [
    Budget(id: 'b1', category: _food, limit: Money(limit), alertPercent: 80),
  ],
  monthTransactions: [_expense(spent)],
  expenseCategories: const [_food],
  now: _now,
);

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  group('rappels d\'échéance', () {
    test('à 9 h le jour de l\'échéance, triés, sur 30 jours', () {
      final notices = NotificationPlan.reminders(
        operations: [
          _op(
            'Salaire',
            380000,
            DateTime(2026, 12),
            kind: TransactionKind.income,
          ),
          _op('Loyer', 75000, DateTime(2026, 11, 20), ask: false),
        ],
        now: _now,
        l10n: _l10n,
        route: '/r',
      );
      expect(notices.map((n) => n.at), [
        DateTime(2026, 11, 20, 9),
        DateTime(2026, 12, 1, 9),
      ]);
      expect(notices.first.title, 'Loyer · 75 000 FCFA aujourd\'hui');
      expect(notices.first.body, contains('à l\'ouverture'));
      expect(notices.last.title, 'Salaire · +380 000 FCFA aujourd\'hui');
      expect(notices.last.body, 'Touche pour l\'enregistrer.');
      expect(notices.map((n) => n.id).toSet(), hasLength(2));
    });

    test('ni modèle en pause, ni échéance passée, ni au-delà de 30 jours', () {
      final notices = NotificationPlan.reminders(
        operations: [
          _op('Pause', 1000, DateTime(2026, 11, 20), paused: true),
          // Aujourd'hui, 9 h déjà passé.
          _op('Ce matin', 1000, DateTime(2026, 11, 15)),
          _op('Loin', 1000, DateTime(2027, 1, 10)),
        ],
        now: _now,
        l10n: _l10n,
        route: '/r',
      );
      // « Ce matin » revient le 15 décembre, dans les 30 jours.
      expect(notices.map((n) => n.at), [DateTime(2026, 12, 15, 9)]);
    });
  });

  group('solde bas', () {
    Forecast forecast(int balance) => Forecast.compute(
      now: DateTime(2026, 11, 15, 9),
      horizon: ForecastHorizon.month,
      balance: Money(balance),
      history: SpendingHistory(
        firstDay: DateTime(2026, 10, 17),
        variableExpenseByDay: {
          for (var k = 0; k < 30; k++) DateTime(2026, 11, 15 - k): 8000,
        },
        netByDay: {
          for (var k = 0; k < 14; k++) DateTime(2026, 11, 15 - k): -8000,
        },
      ),
      recurring: [
        _op(
          'Salaire',
          380000,
          DateTime(2026, 12),
          kind: TransactionKind.income,
        ),
      ],
      planned: const [],
    );

    test('3 jours avant, à 9 h', () {
      final notice = NotificationPlan.lowBalance(
        forecast: forecast(150000),
        now: _now,
        l10n: _l10n,
        route: '/f',
      );
      // Solde bas prévu le 30 nov. (30 000 FCFA).
      expect(notice?.at, DateTime(2026, 11, 27, 9));
      expect(notice?.title, 'Solde bas possible le 30 nov.');
      expect(notice?.body, startsWith('≈ 30 000 FCFA prévus'));
    });

    test('rien sans risque ni prévision', () {
      expect(
        NotificationPlan.lowBalance(
          forecast: forecast(500000),
          now: _now,
          l10n: _l10n,
          route: '/f',
        ),
        isNull,
      );
      expect(
        NotificationPlan.lowBalance(
          forecast: null,
          now: _now,
          l10n: _l10n,
          route: '/f',
        ),
        isNull,
      );
    });
  });

  group('alertes de budget', () {
    test('seuil d\'alerte franchi, une seule fois par niveau', () {
      final warning = _overview(42000);
      final first = NotificationPlan.budgetCrossings(
        overview: warning,
        notified: const {},
        now: _now,
        l10n: _l10n,
        route: '/b',
      );
      expect(first.single.$2.title, 'Alimentation : 84 % du budget utilisé');
      expect(first.single.$2.body, contains('8 000 FCFA'));

      expect(
        NotificationPlan.budgetCrossings(
          overview: warning,
          notified: const {'b1': 1},
          now: _now,
          l10n: _l10n,
          route: '/b',
        ),
        isEmpty,
      );
    });

    test('dépassement après le seuil', () {
      final crossing = NotificationPlan.budgetCrossings(
        overview: _overview(53000),
        notified: const {'b1': 1},
        now: _now,
        l10n: _l10n,
        route: '/b',
      ).single;
      expect(NotificationPlan.alertLevel(crossing.$1), 2);
      expect(crossing.$2.title, 'Alimentation : budget dépassé de 3 000 FCFA');
    });

    test('sous le seuil : rien', () {
      expect(
        NotificationPlan.budgetCrossings(
          overview: _overview(10000),
          notified: const {},
          now: _now,
          l10n: _l10n,
          route: '/b',
        ),
        isEmpty,
      );
    });
  });

  group('rappel de sauvegarde', () {
    PlannedNotice? reminder({DateTime? last, DateTime? first}) =>
        NotificationPlan.backupReminder(
          lastBackup: last,
          firstOperation: first,
          now: _now,
          l10n: _l10n,
          route: '/s',
        );

    test('30 jours après la dernière sauvegarde, à 9 h', () {
      final notice = reminder(
        last: DateTime(2026, 11, 2, 21, 14),
        first: DateTime(2026, 9, 1),
      );
      expect(notice?.at, DateTime(2026, 12, 2, 9));
      expect(notice?.body, 'Ta dernière sauvegarde date du 2 nov.');
    });

    test('jamais sauvegardé : depuis la première opération ; en retard : '
        'le lendemain', () {
      expect(
        reminder(first: DateTime(2026, 11, 10))?.at,
        DateTime(2026, 12, 10, 9),
      );
      expect(
        reminder(first: DateTime(2026, 9, 1))?.at,
        DateTime(2026, 11, 16, 9),
      );
      expect(reminder(), isNull);
    });
  });
}
