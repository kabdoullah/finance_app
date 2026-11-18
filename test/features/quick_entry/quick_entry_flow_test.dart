import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_app.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDatabase();
    final accounts = AccountsRepository(db, () => testNow);
    for (final (name, type) in [
      ('Wave', AccountType.mobileMoney),
      ('Orange Money', AccountType.mobileMoney),
      ('Espèces', AccountType.cash),
    ]) {
      await accounts.create(
        AccountDraft(type: type, name: name, openingBalance: Money(50000)),
      );
    }
  });
  tearDown(() => db.close());

  Future<void> openSheet(WidgetTester tester) async {
    await pumpTestApp(tester, db);
    await tester.tap(find.text('Ajouter').last);
    await tester.pumpAndSettle();
  }

  testWidgets('écrire deux opérations, vérifier, enregistrer', (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('« Taxi 2 500 ce matin avec Wave »'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'Hier, 2 000 de crédit Orange et 1 500 de pain en espèces',
    );
    await tester.pump();
    await tester.tap(find.text('Analyser'));
    await tester.pumpAndSettle();

    expect(find.text('2 opérations détectées'), findsOneWidget);
    expect(
      find.text('Rien n\'est enregistré avant ta confirmation.'),
      findsOneWidget,
    );
    // Total des dépenses : 3 500.
    expect(find.text('−3 500 FCFA'), findsOneWidget);

    await tester.tap(find.text('Enregistrer 2 opérations'));
    await tester.pumpAndSettle();
    expect(find.text('2 opérations enregistrées'), findsOneWidget);

    final rows = await db.select(db.transactions).get();
    expect(rows, hasLength(2));
    expect(rows.map((r) => r.entryMethod), everyElement('text'));
    expect(rows.map((r) => r.amount).toSet(), {2000, 1500});
    for (final row in rows) {
      final day = DateTime.fromMillisecondsSinceEpoch(row.occurredAt);
      expect((day.year, day.month, day.day), (2026, 11, 14));
    }
  });

  testWidgets('rien n\'est enregistré tant qu\'un montant manque', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.tap(find.text('« Taxi 2 500 ce matin avec Wave »'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'taxi wave');
    await tester.pump();
    await tester.tap(find.text('Analyser'));
    await tester.pumpAndSettle();

    expect(find.text('1 opération détectée'), findsOneWidget);
    final save = find.widgetWithText(FilledButton, 'Enregistrer l\'opération');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, '2500');
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
  });

  testWidgets('sans dictée hors ligne : bascule sur le clavier', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('finance_app/speech'),
      (call) async => call.method == 'status' ? 'unsupported' : null,
    );
    await openSheet(tester);
    await tester.tap(find.text('Dicter'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('La dictée hors connexion n\'est pas disponible'),
      findsOneWidget,
    );
    expect(find.text('Analyser'), findsOneWidget);
  });
}
