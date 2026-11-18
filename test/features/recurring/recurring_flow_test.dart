import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/recurring/data/recurring_repository.dart';
import 'package:finance_app/features/recurring/domain/recurrence.dart';
import 'package:finance_app/features/recurring/domain/recurring_draft.dart';
import 'package:finance_app/features/transactions/data/transactions_repository.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_app.dart';

void main() {
  late AppDatabase db;
  late Account wave;
  late RecurringRepository recurring;

  setUp(() async {
    db = newTestDatabase();
    wave = switch (await AccountsRepository(db, () => testNow).create(
      const AccountDraft(
        type: AccountType.mobileMoney,
        name: 'Wave',
        openingBalance: Money(200000),
      ),
    )) {
      Ok(:final value) => value,
      Err(:final failure) => fail('$failure'),
    };
    recurring = RecurringRepository(
      db,
      () => testNow,
      TransactionsRepository(db, () => testNow),
    );
  });
  tearDown(() => db.close());

  Future<void> program({
    required String name,
    required DateTime start,
    required bool ask,
  }) async {
    final result = await recurring.create(
      RecurringDraft(
        kind: TransactionKind.expense,
        name: name,
        amount: const Money(10000),
        frequency: RecurrenceFrequency.month,
        startDate: start,
        categoryId: 'exp.health',
        accountId: wave.id,
        askBeforeRecording: ask,
      ),
    );
    expect(result, isA<Ok<Object>>());
  }

  Future<void> openRecurring(WidgetTester tester) async {
    await tester.tap(find.text('Transactions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Opérations récurrentes'));
    await tester.pumpAndSettle();
  }

  testWidgets('échéance d’hier à confirmer, puis enregistrée', (tester) async {
    await program(
      name: 'Salle de sport',
      start: DateTime(2026, 11, 14),
      ask: true,
    );
    await pumpTestApp(tester, db);
    await openRecurring(tester);

    expect(find.text('À CONFIRMER · ÉCHÉANCE HIER'), findsOneWidget);
    // Total prévu des dépenses du mois.
    expect(find.text('−10 000'), findsWidgets);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('À CONFIRMER · ÉCHÉANCE HIER'), findsNothing);
    expect(
      find.text('Salle de sport enregistrée : −10 000 FCFA sur Wave.'),
      findsOneWidget,
    );
    expect(find.text('Prochaine échéance : 14 déc.'), findsOneWidget);
  });

  testWidgets('programmer une opération depuis le formulaire', (tester) async {
    await pumpTestApp(tester, db);
    await openRecurring(tester);
    expect(find.textContaining('Aucune opération récurrente'), findsOneWidget);

    await tester.tap(find.text('Nouvelle opération récurrente'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Tontine du quartier');
    await tester.enterText(find.byType(TextField).at(1), '40000');
    await tester.pumpAndSettle();
    for (final label in ['Tontine', 'Wave']) {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    // Début par défaut : aujourd'hui (15 nov.).
    expect(find.text('Le 15 de chaque mois'), findsOneWidget);

    await tester.tap(find.text('Programmer'));
    await tester.pumpAndSettle();
    expect(find.text('« Tontine du quartier » programmée'), findsOneWidget);
    expect(
      find.textContaining('Prochaine échéance : 15 nov. 2026.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Voir les opérations récurrentes'));
    await tester.pumpAndSettle();
    expect(find.text('Chaque mois, le 15 · Wave'), findsOneWidget);
    // « Me demander » par défaut : l'échéance du jour attend une confirmation.
    expect(find.text("À CONFIRMER · ÉCHÉANCE AUJOURD'HUI"), findsOneWidget);
  });

  testWidgets('sans confirmation : rattrapage automatique au lancement', (
    tester,
  ) async {
    await program(name: 'Canal+', start: DateTime(2026, 10, 15), ask: false);
    await pumpTestApp(tester, db);

    expect(
      find.text('2 opérations récurrentes enregistrées automatiquement.'),
      findsOneWidget,
    );
    // Les deux échéances (15 oct. et 15 nov.) sont dans les opérations.
    await tester.tap(find.text('Transactions').last);
    await tester.pumpAndSettle();
    expect(find.text('Canal+'), findsOneWidget); // novembre
    await openRecurring(tester);
    expect(find.text('Prochaine échéance : 15 déc.'), findsOneWidget);
  });
}
