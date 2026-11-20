import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
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
}
