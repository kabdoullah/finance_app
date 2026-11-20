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

import '../../helpers/test_app.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDatabase();
    final wave = switch (await AccountsRepository(db, () => testNow).create(
      const AccountDraft(
        type: AccountType.mobileMoney,
        name: 'Wave',
        openingBalance: Money(500000),
      ),
    )) {
      Ok(:final value) => value,
      Err(:final failure) => fail('$failure'),
    };
    final transactions = TransactionsRepository(db, () => testNow);
    for (final (amount, at, category) in [
      (48000, testNow, 'exp.transport.taxi'), // ce mois-ci
      // Historique → moyenne 9 000.
      (27000, DateTime(2026, 10, 8), 'exp.transport'),
    ]) {
      await transactions.create(
        TransactionDraft(
          kind: TransactionKind.expense,
          amount: Money(amount),
          occurredAt: at,
          accountId: wave.id,
          categoryId: category,
        ),
      );
    }
  });
  tearDown(() => db.close());

  Future<void> openBudgets(WidgetTester tester) async {
    await pumpTestApp(tester, db);
    await tester.tap(find.text('Budgets').last);
    await tester.pumpAndSettle();
  }

  testWidgets('budget par catégorie dépassé : statut, alerte et accueil', (
    tester,
  ) async {
    await openBudgets(tester);
    expect(find.textContaining('Aucun budget pour l'), findsOneWidget);

    await tester.tap(find.text('Créer un budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transport'));
    await tester.pumpAndSettle();
    // Suggestion : 27 000 FCFA sur les 3 derniers mois → 9 000 par mois.
    expect(
      find.text('Ces 3 derniers mois, tu as dépensé en moyenne 9 000 FCFA.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), '45000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer le budget'));
    await tester.pumpAndSettle();
    expect(find.text('Budget Transport créé'), findsOneWidget);
    expect(
      find.text('45\u00a0000\u00a0FCFA par mois · alerte à 80\u00a0%'),
      findsOneWidget,
    );
    await tester.tap(find.text('Voir mes budgets'));
    await tester.pumpAndSettle();

    expect(find.text('Dépassé de 3 000'), findsOneWidget);
    expect(
      find.textContaining('Transport : budget dépassé de 3 000 FCFA.'),
      findsOneWidget,
    );
    expect(find.text('48 000 sur 45 000'), findsOneWidget);
    expect(
      find.textContaining('Surtout à cause de Taxi : 1 opération, 48 000 FCFA'),
      findsOneWidget,
    );

    // « Voir les opérations » de l'alerte : Transactions filtré sur Transport.
    await tester.tap(find.text('Voir les opérations').first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Transport'), findsOneWidget);
    await tester.tap(find.text('Budgets').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Dépassé de 3 000'), 200);
    expect(find.text('Dépassé de 3 000'), findsOneWidget);
  });

  testWidgets('budget global : reste du mois, puis suppression', (
    tester,
  ) async {
    await openBudgets(tester);
    await tester.tap(find.text('Créer un budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toutes les dépenses'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '300000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer le budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir mes budgets'));
    await tester.pumpAndSettle();

    expect(find.text('Budget de novembre'), findsOneWidget);
    // 15 novembre : 16 jours restants, aujourd'hui compris ;
    // 252 000 / 16 = 15 750 → 15 700 par jour.
    expect(find.text('Encore 16 jours'), findsOneWidget);
    // Repères sous la barre du mois.
    expect(find.text('1er nov.'), findsOneWidget);
    expect(find.text("Aujourd'hui"), findsOneWidget);
    expect(find.text('30 nov.'), findsOneWidget);
    expect(
      find.text(
        "Il te reste 252 000 FCFA jusqu'à la fin du mois, "
        'soit environ 15 700 FCFA par jour.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Budget de novembre'));
    await tester.pumpAndSettle();
    expect(find.text('Modifier le budget'), findsOneWidget);
    await tester.tap(find.text('Supprimer ce budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer ce budget').last);
    await tester.pumpAndSettle();
    expect(find.text('Budget de novembre'), findsNothing);
    expect(find.text('Définir un budget pour tout le mois'), findsOneWidget);
  });
}
