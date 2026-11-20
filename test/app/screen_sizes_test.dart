import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/transactions/data/transactions_repository.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/features/transactions/domain/transaction_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

/// Les cinq onglets s'affichent sans débordement (qui ferait échouer le
/// test) sur petit écran, avec un texte agrandi et en paysage.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDatabase();
    final account = switch (await AccountsRepository(db, () => testNow).create(
      const AccountDraft(
        type: AccountType.mobileMoney,
        name: 'Orange Money Pro',
        openingBalance: Money(1250000),
      ),
    )) {
      Ok(:final value) => value,
      Err(:final failure) => fail('$failure'),
    };
    // 20 jours de dépenses : prévision, répartition et carte 30 jours.
    final transactions = TransactionsRepository(db, () => testNow);
    for (var day = 0; day < 20; day++) {
      await transactions.create(
        TransactionDraft(
          kind: TransactionKind.expense,
          amount: Money(12500 + day * 100),
          occurredAt: testNow.subtract(Duration(days: day)),
          accountId: account.id,
          categoryId: day.isEven ? 'exp.food' : 'exp.transport',
        ),
      );
    }
  });
  tearDown(() => db.close());

  const screens = <String, (Size, double)>{
    'petit téléphone 320 × 568': (Size(320, 568), 1),
    '360 × 640, texte ×1,5': (Size(360, 640), 1.5),
    '390 × 844, texte ×2': (Size(390, 844), 2),
    'paysage 844 × 390': (Size(844, 390), 1),
  };
  const tabs = [
    'Accueil',
    'Transactions',
    'Budgets',
    'Prévisions',
    'Assistant',
  ];

  for (final MapEntry(key: name, value: (size, textScale)) in screens.entries) {
    testWidgets('onglets sans débordement : $name', (tester) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(buildTestApp(db));
      await tester.pumpAndSettle();
      for (final tab in tabs) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
      }
    });
  }
}
