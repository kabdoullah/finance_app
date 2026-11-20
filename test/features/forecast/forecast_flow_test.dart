import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/forecast/presentation/forecast_page.dart';
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
  late Account wave;
  late TransactionsRepository transactions;

  setUp(() async {
    db = newTestDatabase();
    wave = switch (await AccountsRepository(db, () => testNow).create(
      const AccountDraft(
        type: AccountType.mobileMoney,
        name: 'Wave',
        openingBalance: Money(300000),
      ),
    )) {
      Ok(:final value) => value,
      Err(:final failure) => fail('$failure'),
    };
    transactions = TransactionsRepository(db, () => testNow);
  });
  tearDown(() => db.close());

  Future<void> expense(int amount, DateTime at) async {
    final result = await transactions.create(
      TransactionDraft(
        kind: TransactionKind.expense,
        amount: Money(amount),
        occurredAt: at,
        accountId: wave.id,
        categoryId: 'exp.food',
      ),
    );
    expect(result, isA<Ok<Transaction>>());
  }

  /// Fait défiler la liste de l'onglet Prévisions (les autres onglets
  /// restent montés et ont leurs propres listes).
  Future<void> scrollTo(WidgetTester tester, Finder target, double delta) =>
      tester.scrollUntilVisible(
        target,
        delta,
        scrollable: find
            .descendant(
              of: find.byType(ForecastPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );

  Future<void> openForecast(WidgetTester tester) async {
    await pumpTestApp(tester, db);
    await tester.tap(find.text('Prévisions').last);
    await tester.pumpAndSettle();
  }

  testWidgets('moins de 14 jours d’opérations : pas encore de prévision', (
    tester,
  ) async {
    await expense(5000, testNow);
    await openForecast(tester);

    expect(find.text('Pas encore assez de données'), findsOneWidget);
    expect(find.text('1 jour sur 14'), findsOneWidget);
    expect(find.text('Encore 13 jours'), findsOneWidget);
    expect(find.text('Ajouter une opération'), findsOneWidget);
  });

  testWidgets('pas encore de prévision : tient avec un texte agrandi ×2', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await expense(5000, testNow);
    await openForecast(tester);

    expect(find.text('Encore 13 jours'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('prévision à 30 puis 7 jours avec un salaire récurrent', (
    tester,
  ) async {
    // 20 jours d'historique, 15 000 de dépenses : 750 par jour.
    await expense(10000, DateTime(2026, 10, 27, 12));
    await expense(5000, testNow);
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
    await openForecast(tester);

    // 30 jours : 285 000 − 30 × 750 + 380 000 = 642 500 ≈ 643 000.
    expect(find.text('Solde actuel'), findsOneWidget);
    expect(find.text('Prévu au 15 déc.'), findsOneWidget);
    expect(find.text('≈ 643 000'), findsOneWidget);
    // Moins de 30 jours d'historique : fiabilité abaissée d'un cran.
    expect(find.text('Fiabilité faible'), findsOneWidget);
    final noNegative = find.text("Aucun solde négatif prévu d'ici le 15 déc.");
    await scrollTo(tester, noNegative, 200);
    expect(noNegative, findsOneWidget);
    await scrollTo(tester, find.text('Salaire'), 200);
    expect(find.text('+380 000'), findsWidgets);
    expect(find.text('≈ −750'), findsOneWidget);

    // 7 jours : 285 000 − 7 × 750 = 279 750 ≈ 280 000.
    await scrollTo(tester, find.text('7 jours'), -200);
    await tester.tap(find.text('7 jours'));
    await tester.pumpAndSettle();
    expect(find.text('Prévu au 22 nov.'), findsOneWidget);
    expect(find.text('≈ 280 000'), findsOneWidget);
    expect(find.text('Fiabilité moyenne'), findsOneWidget);
  });
}
