import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/budgets/data/budgets_repository.dart';
import 'package:finance_app/features/budgets/domain/budget_draft.dart';
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
        openingBalance: Money(200000),
      ),
    )) {
      Ok<Account>(:final value) => value,
      Err(:final failure) => fail('$failure'),
    };
    final transactions = TransactionsRepository(db, () => testNow);
    for (var day = 2; day <= 12; day++) {
      await transactions.create(
        TransactionDraft(
          kind: TransactionKind.expense,
          amount: const Money(3000),
          occurredAt: DateTime(2026, 11, day, 8),
          accountId: wave.id,
          categoryId: 'exp.transport.taxi',
        ),
      );
    }
    await BudgetsRepository(db, () => testNow).create(
      const BudgetDraft(limit: Money(30000), categoryId: 'exp.transport'),
    );
  });
  tearDown(() => db.close());

  const sentence =
      'Ton budget Transport est dépassé de 3 000 FCFA, surtout à cause '
      'de Taxi (11 opérations).';

  testWidgets('suggestion sur l\'accueil, Copilote, interrupteur', (
    tester,
  ) async {
    await pumpTestApp(tester, db);
    expect(find.text(sentence), findsOneWidget);

    // Montants masqués : la suggestion aussi.
    await tester.tap(find.byTooltip('Masquer les montants'));
    await tester.pumpAndSettle();
    expect(find.text(sentence), findsNothing);
    await tester.tap(find.byTooltip('Afficher les montants'));
    await tester.pumpAndSettle();
    expect(find.text(sentence), findsOneWidget);

    await tester.ensureVisible(find.text('Demander au Copilote'));
    await tester.tap(find.text('Demander au Copilote'));
    await tester.pumpAndSettle();
    // Assistant non chargé dans les tests : l'onglet s'ouvre tel quel.
    expect(find.text('Copilote'), findsOneWidget);

    await tester.tap(find.text('Accueil').last);
    await tester.pumpAndSettle();
    // L'accueil a gardé sa position : bouton Paramètres en haut.
    await tester.ensureVisible(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tapSetting(tester, 'Suggestions du Copilote');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text(sentence), findsNothing);
  });
}
