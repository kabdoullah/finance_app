import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/forecast/presentation/forecast_page.dart';
import 'package:finance_app/features/forecast/presentation/simulation_page.dart';
import 'package:finance_app/features/goals/data/goals_repository.dart';
import 'package:finance_app/features/goals/domain/goal_draft.dart';
import 'package:finance_app/features/goals/domain/savings_goal.dart';
import 'package:finance_app/features/recurring/data/recurring_repository.dart';
import 'package:finance_app/features/recurring/domain/recurrence.dart';
import 'package:finance_app/features/recurring/domain/recurring_draft.dart';
import 'package:finance_app/features/transactions/data/transactions_repository.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/features/transactions/domain/transaction_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_app.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDatabase();
    final accounts = AccountsRepository(db, () => testNow);
    final wave = switch (await accounts.create(
      const AccountDraft(
        type: AccountType.mobileMoney,
        name: 'Wave',
        openingBalance: Money(300000),
      ),
    )) {
      Ok(:final value) => value,
      Err(:final failure) => fail('$failure'),
    };
    final transactions = TransactionsRepository(db, () => testNow);
    // 20 jours d'historique, 15 000 de dépenses : 750 par jour.
    for (final (amount, at) in [
      (10000, DateTime(2026, 10, 27, 12)),
      (5000, testNow),
    ]) {
      await transactions.create(
        TransactionDraft(
          kind: TransactionKind.expense,
          amount: Money(amount),
          occurredAt: at,
          accountId: wave.id,
          categoryId: 'exp.food',
        ),
      );
    }
    await RecurringRepository(db, () => testNow, transactions).create(
      RecurringDraft(
        kind: TransactionKind.income,
        name: 'Salaire',
        amount: const Money(380000),
        frequency: RecurrenceFrequency.month,
        startDate: DateTime(2026, 12),
        categoryId: 'inc.salary',
        accountId: wave.id,
      ),
    );
    // Objectif « Téléphone » : 60 000 réservés sur Wave.
    final goals = GoalsRepository(db, () => testNow, accounts);
    final goal = await goals.create(
      GoalDraft(
        name: 'Téléphone',
        target: const Money(150000),
        iconKey: 'phone',
        targetDate: DateTime(2027, 3, 31),
      ),
    );
    await goals.contribute(
      (goal as Ok<SavingsGoal>).value.id,
      wave.id,
      const Money(60000),
    );
  });
  tearDown(() => db.close());

  Finder scrollableOf(Type page) => find
      .descendant(of: find.byType(page), matching: find.byType(Scrollable))
      .first;

  testWidgets('simuler un achat : verdict, épargne, salaire, objectif', (
    tester,
  ) async {
    await pumpTestApp(tester, db);
    await tester.tap(find.text('Prévisions').last);
    await tester.pumpAndSettle();
    final simulate = find.text('Simuler un achat');
    await tester.scrollUntilVisible(
      simulate,
      300,
      scrollable: scrollableOf(ForecastPage),
    );
    await tester.ensureVisible(simulate);
    await tester.pumpAndSettle();
    await tester.tap(simulate);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Téléphone');
    await tester.enterText(find.byType(TextField).at(1), '240000');
    await tester.pumpAndSettle();

    // Disponible : 285 000 − 60 000 réservés − 240 000 < 0 dès aujourd'hui.
    final verdict = find.text('Déconseillé');
    await tester.scrollUntilVisible(
      verdict,
      200,
      scrollable: scrollableOf(SimulationPage),
    );
    expect(
      find.textContaining('passerait sous zéro à partir du 15 nov.'),
      findsOneWidget,
    );
    // Sans achat au 15 déc. : 285 000 − 22 500 + 380 000 − 60 000.
    expect(find.text('sans achat : ≈ 583 000'), findsOneWidget);

    // Avec l'épargne « Téléphone » : coût ramené à 180 000.
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Possible'), findsOneWidget);

    // Sans épargne mais après le salaire du 1er déc. : possible aussi.
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Après « Salaire » (1er déc.)'));
    await tester.tap(find.text('Après « Salaire » (1er déc.)'));
    await tester.pumpAndSettle();
    expect(find.text('Possible'), findsOneWidget);

    final createGoal = find.text('Créer un objectif pour cet achat');
    await tester.scrollUntilVisible(
      createGoal,
      200,
      scrollable: scrollableOf(SimulationPage),
    );
    await tester.tap(createGoal);
    await tester.pumpAndSettle();
    expect(find.text('Nouvel objectif'), findsOneWidget);
    expect(find.text('240 000'), findsOneWidget);
  });
}
