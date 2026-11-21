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
import 'package:material_ui/material_ui.dart';

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

  testWidgets('filtrer par compte puis par catégorie, et tout afficher', (
    tester,
  ) async {
    await pumpTestApp(tester, db);
    await tester.tap(find.text('Transactions').last);
    await tester.pumpAndSettle();
    expect(find.text('Transport · Wave'), findsOneWidget);
    expect(find.text('Logement · Ecobank'), findsOneWidget);

    // Feuille « Filtres » : compte Ecobank.
    await tester.tap(find.text('Filtres'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ecobank').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ecobank').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir 1 opération'));
    await tester.pumpAndSettle();
    expect(find.text('Logement · Ecobank'), findsOneWidget);
    expect(find.text('Transport · Wave'), findsNothing);
    expect(find.widgetWithText(InputChip, 'Ecobank'), findsOneWidget);

    // Puis Transport : plus rien sur Ecobank.
    await tester.tap(find.text('Filtres · 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transport'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune opération'), findsOneWidget);
    await tester.tap(find.text('Aucune opération'));
    await tester.pumpAndSettle();
    expect(find.text('Rien sur cette période'), findsOneWidget);

    // Le bouton est sous les boutons d'ajout : défiler les efface.
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tout afficher'));
    await tester.pumpAndSettle();
    expect(find.text('Transport · Wave'), findsOneWidget);
    expect(find.text('Logement · Ecobank'), findsOneWidget);
  });

  testWidgets('retirer un filtre actif d’un toucher', (tester) async {
    await pumpTestApp(tester, db);
    await tester.tap(find.text('Transactions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filtres'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Wave').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wave').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir 1 opération'));
    await tester.pumpAndSettle();
    expect(find.text('Logement · Ecobank'), findsNothing);

    await tester.tap(find.byTooltip('Retirer le filtre Wave'));
    await tester.pumpAndSettle();
    expect(find.text('Logement · Ecobank'), findsOneWidget);
  });
}
