import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/planned/data/planned_repository.dart';
import 'package:finance_app/features/planned/domain/planned_draft.dart';
import 'package:finance_app/features/transactions/data/transactions_repository.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/features/transactions/domain/transaction_draft.dart';
import 'package:finance_app/features/transactions/presentation/add_transaction_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_app.dart';

const _nbsp = '\u00a0';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDatabase();
    await AccountsRepository(db, () => testNow).create(
      const AccountDraft(
        type: AccountType.bank,
        name: 'Ecobank',
        openingBalance: Money(217500),
      ),
    );
  });
  tearDown(() => db.close());

  /// Ajouter › Dépense › 15 000 › Continuer › Planifiée.
  Future<void> openPlannedForm(WidgetTester tester) async {
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dépense'));
    await tester.pumpAndSettle();
    for (final key in ['1', '5', '000']) {
      await tester.tap(find.text(key));
      await tester.pump();
    }
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Planifiée'));
    await tester.pumpAndSettle();
  }

  testWidgets('planifier une dépense, la retrouver puis la payer', (
    tester,
  ) async {
    await pumpTestApp(tester, db);
    await openPlannedForm(tester);

    expect(
      find.text("À payer plus tard : rien ne sort de ton compte aujourd'hui."),
      findsOneWidget,
    );
    // Sans libellé : le champ passe en erreur, rien n'est enregistré.
    await tester.tap(find.text('Éducation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Planifier la dépense'));
    await tester.pumpAndSettle();
    expect(find.text('« Scolarité » planifiée'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'Scolarité');
    await tester.tap(find.text('Planifier la dépense'));
    await tester.pumpAndSettle();

    expect(find.text('« Scolarité » planifiée'), findsOneWidget);
    expect(
      find.text('Éducation · Ecobank · à payer le 16 nov.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Voir la dépense'));
    await tester.pumpAndSettle();
    expect(find.text('Dépense planifiée'), findsOneWidget);
    expect(find.text('Pas encore'), findsOneWidget);

    // Dans Transactions : groupe « À venir », solde inchangé.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('À venir'), findsOneWidget);
    expect(find.text('15${_nbsp}000 à payer'), findsOneWidget);

    await tester.tap(find.text('Scolarité'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marquer comme payée'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer le paiement'));
    await tester.pumpAndSettle();

    // Devenue une opération qui garde sa date prévue.
    expect(find.text('Date prévue'), findsOneWidget);
    expect(find.text('Lundi 16 nov. 2026'), findsOneWidget);
    expect(find.text('Payée en avance'), findsOneWidget);
    expect(
      find.text('Solde après : 202${_nbsp}500${_nbsp}FCFA'),
      findsOneWidget,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('À venir'), findsNothing);
  });

  testWidgets('calendrier de l’accueil : jour, planifier ce jour-là, '
      'dépenses du mois', (tester) async {
    final accountId = (await AccountsRepository(
      db,
      () => testNow,
    ).watchActive().first).single.id;
    final transactions = TransactionsRepository(db, () => testNow);
    await transactions.create(
      TransactionDraft(
        kind: TransactionKind.expense,
        amount: const Money(8500),
        occurredAt: testNow,
        accountId: accountId,
        categoryId: 'exp.food',
        description: 'Marché',
      ),
    );
    await PlannedRepository(db, () => testNow, transactions).create(
      PlannedDraft(
        name: 'Facture CIE',
        amount: const Money(14000),
        dueDate: DateTime(2026, 11, 20),
        categoryId: 'exp.bills',
        accountId: accountId,
      ),
    );
    await pumpTestApp(tester, db);

    expect(find.text('Calendrier'), findsOneWidget);
    expect(find.text('8${_nbsp}500${_nbsp}FCFA dépensés'), findsOneWidget);
    expect(find.text('Dépenses de novembre'), findsOneWidget);

    // Le 20 n'est pas dans la semaine affichée : grille complète.
    await tester.ensureVisible(find.text('Voir tout le mois'));
    await tester.tap(find.text('Voir tout le mois'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Vendredi 20 nov')));
    await tester.pumpAndSettle();
    expect(find.text('Facture CIE'), findsOneWidget);
    expect(find.text('14${_nbsp}000${_nbsp}FCFA à payer'), findsOneWidget);

    // Jour futur sans rien : planifier ce jour-là.
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Samedi 21 nov')));
    await tester.pumpAndSettle();
    expect(find.text('Rien de prévu ce jour-là.'), findsOneWidget);
    await tester.ensureVisible(find.text('Planifier une dépense ce jour-là'));
    await tester.tap(find.text('Planifier une dépense ce jour-là'));
    await tester.pumpAndSettle();
    for (final key in ['5', '000']) {
      await tester.tap(find.text(key));
      await tester.pump();
    }
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Samedi 21 nov. 2026'),
      200,
      scrollable: scrollableOf(AddTransactionPage),
    );
    expect(find.text('Samedi 21 nov. 2026'), findsOneWidget);
    expect(find.text('Planifier la dépense'), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Voir les dépenses de novembre'));
    await tester.tap(find.text('Voir les dépenses de novembre'));
    await tester.pumpAndSettle();
    expect(find.text('Dépenses du mois'), findsOneWidget);
    expect(find.text('À payer · 14${_nbsp}000${_nbsp}FCFA'), findsOneWidget);
    expect(find.text('Payées · 8${_nbsp}500${_nbsp}FCFA'), findsOneWidget);
    expect(find.text('22${_nbsp}500'), findsOneWidget);
  });
}
