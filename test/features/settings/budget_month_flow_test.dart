import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/budgets/data/budgets_repository.dart';
import 'package:finance_app/features/budgets/domain/budget_draft.dart';
import 'package:finance_app/features/settings/presentation/settings_providers.dart';
import 'package:finance_app/features/transactions/data/transactions_repository.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/features/transactions/domain/transaction_draft.dart';
import 'package:finance_app/features/transactions/presentation/transactions_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_app.dart';

void main() {
  late AppDatabase db;

  // testNow : 15 nov. 2026.
  setUp(() async {
    db = newTestDatabase();
    final wave = switch (await AccountsRepository(db, () => testNow).create(
      const AccountDraft(
        type: AccountType.mobileMoney,
        name: 'Wave',
        openingBalance: Money(100000),
      ),
    )) {
      Ok<Account>(:final value) => value,
      Err(:final failure) => fail('$failure'),
    };
    final transactions = TransactionsRepository(db, () => testNow);
    for (final (amount, day) in [
      (10000, DateTime(2026, 10, 28)),
      (5000, DateTime(2026, 11, 10)),
    ]) {
      await transactions.create(
        TransactionDraft(
          kind: TransactionKind.expense,
          amount: Money(amount),
          occurredAt: day.add(const Duration(hours: 12)),
          accountId: wave.id,
          categoryId: 'exp.food',
        ),
      );
    }
    await BudgetsRepository(
      db,
      () => testNow,
    ).create(const BudgetDraft(limit: Money(50000)));
  });
  tearDown(() => db.close());

  Finder monthExpense(String amount) => find.descendant(
    of: find
        .ancestor(
          of: find.text('Sorties · novembre'),
          matching: find.byType(Column),
        )
        .first,
    matching: find.text(amount),
  );

  testWidgets('début le 25 : du 25 oct. au 24 nov., nommé « novembre »', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      db,
      overrides: [
        budgetMonthStartProvider.overrideWith(() => BudgetMonthStart(25)),
      ],
    );
    // Accueil : la dépense du 28 oct. compte dans « novembre ».
    expect(monthExpense('15 000'), findsOneWidget);
    // Aussi en tête du calendrier de l'accueil.
    expect(find.text('Novembre · 25 oct. – 24 nov.'), findsNWidgets(2));

    await tester.tap(find.text('Budgets').last);
    await tester.pumpAndSettle();
    expect(find.text('Budget global · novembre · 25 oct. – 24 nov.'), findsOneWidget);
    // 15 → 24 nov. inclus.
    expect(find.text('Encore 10 jours'), findsOneWidget);

    await tester.tap(find.text('Transactions').last);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(TransactionsPage),
        matching: find.text('Novembre · 25 oct. – 24 nov.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('réglage dans les Paramètres : le 1er puis le 5', (tester) async {
    await pumpTestApp(tester, db);
    // Mois calendaire : seule la dépense du 10 nov.
    expect(monthExpense('5 000'), findsOneWidget);

    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    expect(find.text('Le 1er'), findsOneWidget);
    await tapSetting(tester, 'Début du mois budgétaire');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Le 5'));
    await tester.pumpAndSettle();
    expect(find.text('Le 5'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    // Du 5 nov. au 4 déc. : toujours la seule dépense du 10 nov.
    expect(find.text('Novembre · 5 nov. – 4 déc.'), findsNWidgets(2));
    expect(monthExpense('5 000'), findsOneWidget);
  });
}
