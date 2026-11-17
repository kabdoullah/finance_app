import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/transactions/data/transactions_repository.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/features/transactions/domain/transaction_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDatabase();
    final accounts = AccountsRepository(db, () => testNow);
    final transactions = TransactionsRepository(db, () => testNow);
    Future<Account> account(String name, AccountType type) async =>
        switch (await accounts.create(
          AccountDraft(
            type: type,
            name: name,
            openingBalance: const Money(200000),
          ),
        )) {
          Ok(:final value) => value,
          Err(:final failure) => fail('$failure'),
        };
    final wave = await account('Wave', AccountType.mobileMoney);
    final ecobank = await account('Ecobank', AccountType.bank);
    for (final (accountId, category, amount) in [
      (wave.id, 'exp.transport', 2500),
      (ecobank.id, 'exp.housing', 75000),
    ]) {
      await transactions.create(
        TransactionDraft(
          kind: TransactionKind.expense,
          amount: Money(amount),
          occurredAt: testNow,
          accountId: accountId,
          categoryId: category,
        ),
      );
    }
  });
  tearDown(() => db.close());

  testWidgets('l’accueil montre « Où va ton argent »', (tester) async {
    await pumpTestApp(tester, db);

    expect(find.text('Où va ton argent'), findsOneWidget);
    // 75 000 / 77 500 ≈ 96,8 % ; 2 500 / 77 500 ≈ 3,2 %.
    expect(find.text('97 %'), findsOneWidget);
    expect(find.text('3 %'), findsOneWidget);
  });

  testWidgets('filtrer par compte puis par catégorie, et réinitialiser', (
    tester,
  ) async {
    await pumpTestApp(tester, db);
    await tester.tap(find.text('Transactions').last);
    await tester.pumpAndSettle();
    expect(find.text('Transport · Wave'), findsOneWidget);
    expect(find.text('Logement · Ecobank'), findsOneWidget);

    await tester.tap(find.text('Tous les comptes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ecobank'));
    await tester.pumpAndSettle();
    expect(find.text('Logement · Ecobank'), findsOneWidget);
    expect(find.text('Transport · Wave'), findsNothing);

    // La rangée de filtres défile horizontalement.
    await tester.ensureVisible(find.text('Toutes catégories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toutes catégories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transport'));
    await tester.pumpAndSettle();
    expect(
      find.text('Aucune opération ne correspond à ces filtres en novembre.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Réinitialiser les filtres'));
    await tester.pumpAndSettle();
    expect(find.text('Transport · Wave'), findsOneWidget);
    expect(find.text('Logement · Ecobank'), findsOneWidget);
  });
}
