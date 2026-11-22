import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/goals/data/goals_repository.dart';
import 'package:finance_app/features/goals/domain/goal_draft.dart';
import 'package:finance_app/features/goals/domain/savings_goal.dart';
import 'package:finance_app/features/goals/presentation/goal_detail_page.dart';
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
  late AccountsRepository accounts;
  late Account wave;

  setUp(() async {
    db = newTestDatabase();
    accounts = AccountsRepository(db, () => testNow);
    wave = switch (await accounts.create(
      const AccountDraft(
        type: AccountType.mobileMoney,
        name: 'Wave',
        openingBalance: Money(42000),
      ),
    )) {
      Ok(:final value) => value,
      Err(:final failure) => fail('$failure'),
    };
  });
  tearDown(() => db.close());

  Future<void> openGoals(WidgetTester tester) async {
    await pumpTestApp(tester, db);
    await tester.tap(find.text('Budgets').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objectifs'));
    await tester.pumpAndSettle();
  }

  testWidgets('fonds d’urgence : 3 mois de dépenses suggérés', (
    tester,
  ) async {
    final transactions = TransactionsRepository(db, () => testNow);
    for (final (amount, month) in [(90000, 8), (55000, 9), (35000, 10)]) {
      await transactions.create(
        TransactionDraft(
          kind: TransactionKind.expense,
          amount: Money(amount),
          occurredAt: DateTime(2026, month, 10),
          accountId: wave.id,
          categoryId: 'exp.food',
        ),
      );
    }
    await openGoals(tester);

    await tester.tap(find.text('Nouvel objectif'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Fonds d'urgence"));
    await tester.pumpAndSettle();
    // (90 000 + 55 000 + 35 000) ÷ 3 = 60 000 par mois → 180 000.
    expect(
      find.text('3 mois de tes dépenses ≈ 180 000 FCFA.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Utiliser ce montant'));
    await tester.pumpAndSettle();
    expect(find.text('180 000'), findsOneWidget);

    await tester.tap(find.text('Sans date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Créer l'objectif"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir mes objectifs'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'Objectif conseillé : 3 mois de dépenses '
        '(≈ 180 000 FCFA).',
      ),
      findsOneWidget,
    );
  });

  testWidgets('objectif en retard : conseil, report de date et disponible', (
    tester,
  ) async {
    // Objectif créé il y a 60 jours, 10 000 épargnés depuis : en retard.
    final past = testNow.subtract(const Duration(days: 60));
    final oldGoals = GoalsRepository(db, () => past, accounts);
    final created = await oldGoals.create(
      GoalDraft(
        name: 'Téléphone',
        target: const Money(150000),
        iconKey: 'phone',
        targetDate: DateTime(2027, 1, 31),
      ),
    );
    final goalId = (created as Ok<SavingsGoal>).value.id;
    await oldGoals.contribute(goalId, wave.id, const Money(10000));
    await RecurringRepository(
      db,
      () => testNow,
      TransactionsRepository(db, () => testNow),
    ).create(
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

    await openGoals(tester);
    await tester.tap(find.text('Téléphone'));
    await tester.pumpAndSettle();

    final postpone = find.textContaining('Repousser au');
    await tester.scrollUntilVisible(
      postpone,
      200,
      scrollable: find
          .descendant(
            of: find.byType(GoalDetailPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    // 140 000 restants en ≈ 2,5 mois : ≈ 55 400 par mois, au salaire.
    expect(
      find.textContaining(
        'Pour tenir la date : verse 55 400 FCFA le jour de '
        '« Salaire » (le 1er), ou repousse la date au',
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(postpone);
    await tester.pumpAndSettle();
    await tester.tap(postpone);
    await tester.pumpAndSettle();
    expect(find.textContaining('Date repoussée au'), findsOneWidget);

    // Page Comptes et détail du compte : part réservée et disponible.
    await openAccounts(tester);
    expect(find.text('dont 10 000 réservés'), findsOneWidget);
    await tester.tap(find.text('Wave'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Disponible : 32 000 FCFA · '
        '10 000 réservés aux objectifs',
      ),
      findsOneWidget,
    );
  });
}
