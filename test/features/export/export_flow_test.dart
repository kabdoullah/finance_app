import 'dart:convert';
import 'dart:typed_data';

import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/files/file_output.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/transactions/data/transactions_repository.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/features/transactions/domain/transaction_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

class _FakeOutput extends FileOutput {
  final saved = <(String, Uint8List, String)>[];

  @override
  Future<bool> save(String fileName, Uint8List bytes, String mimeType) async {
    saved.add((fileName, bytes, mimeType));
    return true;
  }
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDatabase();
    final wave = switch (await AccountsRepository(db, () => testNow).create(
      const AccountDraft(
        type: AccountType.mobileMoney,
        name: 'Wave',
        openingBalance: Money(10000),
      ),
    )) {
      Ok<Account>(:final value) => value,
      Err(:final failure) => fail('$failure'),
    };
    await TransactionsRepository(db, () => testNow).create(
      TransactionDraft(
        kind: TransactionKind.expense,
        amount: const Money(2500),
        occurredAt: DateTime(2026, 11, 14, 8),
        accountId: wave.id,
        categoryId: 'exp.transport',
      ),
    );
  });
  tearDown(() => db.close());

  testWidgets('Paramètres › Exporter : CSV puis relevé PDF du mois', (
    tester,
  ) async {
    final output = _FakeOutput();
    await pumpTestApp(
      tester,
      db,
      overrides: [fileOutputProvider.overrideWithValue(output)],
    );
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tapSetting(tester, 'Exporter mes données');
    await tester.pumpAndSettle();
    expect(find.textContaining('n\'est pas chiffré'), findsOneWidget);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final (csvName, csv, csvMime) = output.saved.single;
    expect(csvName, 'finance-copilot-operations-2026-11-15.csv');
    expect(csvMime, 'text/csv');
    expect(utf8.decode(csv.skip(3).toList()), contains(';-2500;Transport;'));
    expect(find.text('Fichier enregistré.'), findsOneWidget);

    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();
    expect(find.text('novembre 2026'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Enregistrer'));
      // Polices lues dans les ressources : vraie attente.
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pumpAndSettle();
    final (pdfName, pdf, pdfMime) = output.saved.last;
    expect(pdfName, 'finance-copilot-releve-2026-11.pdf');
    expect(pdfMime, 'application/pdf');
    expect(ascii.decode(pdf.take(5).toList()), '%PDF-');
  });
}
