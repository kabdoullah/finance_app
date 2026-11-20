import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

const _nbsp = ' ';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDatabase();
    await AccountsRepository(db, () => testNow).create(
      const AccountDraft(
        type: AccountType.mobileMoney,
        name: 'Wave',
        openingBalance: Money(42000),
      ),
    );
  });
  tearDown(() => db.close());

  Future<void> addExpense(WidgetTester tester) async {
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dépense'));
    await tester.pumpAndSettle();

    // 2 500 au clavier de la maquette.
    for (final key in ['2', '5', '0', '0']) {
      await tester.tap(find.text(key));
      await tester.pump();
    }
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transport'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer la dépense'));
    await tester.pumpAndSettle();
  }

  testWidgets('ajouter une dépense met à jour le solde et l’accueil', (
    tester,
  ) async {
    await pumpTestApp(tester, db);

    await addExpense(tester);

    expect(find.text('Dépense enregistrée'), findsOneWidget);
    expect(find.text('Nouveau solde Wave'), findsOneWidget);
    expect(find.text('39${_nbsp}500${_nbsp}FCFA'), findsOneWidget);

    await tester.tap(find.text("Retour à l'accueil"));
    await tester.pumpAndSettle();

    // Accueil « actif » : dernières opérations au lieu des étapes.
    expect(find.text('Dernières opérations'), findsOneWidget);
    expect(find.text('Pour bien démarrer'), findsNothing);
    // Dans « Dernières opérations » et dans le jour du calendrier.
    expect(find.text('Transport · Wave'), findsNWidgets(2));
    expect(find.text('−2${_nbsp}500'), findsNWidgets(2));
  });

  testWidgets('supprimer une opération puis annuler la suppression', (
    tester,
  ) async {
    await pumpTestApp(tester, db);
    await addExpense(tester);
    await tester.tap(find.text("Retour à l'accueil"));
    await tester.pumpAndSettle();

    // Le calendrier pousse « Dernières opérations » plus bas.
    await tester.ensureVisible(find.text('Transport · Wave').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transport · Wave').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Solde après : 39${_nbsp}500${_nbsp}FCFA'),
      findsOneWidget,
    );

    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer cette dépense ?'), findsOneWidget);
    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();
    expect(find.text('Opération supprimée'), findsOneWidget);

    await tester.tap(find.text('Annuler la suppression'));
    await tester.pumpAndSettle();
    expect(
      find.text('Solde après : 39${_nbsp}500${_nbsp}FCFA'),
      findsOneWidget,
    );
  });

  testWidgets('l’onglet Transactions liste et filtre les opérations', (
    tester,
  ) async {
    await pumpTestApp(tester, db);
    await addExpense(tester);
    await tester.tap(find.text("Retour à l'accueil"));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transactions').last);
    await tester.pumpAndSettle();
    // Résumé : payées, planifiées, nombre d'opérations.
    expect(find.text('−2${_nbsp}500'), findsWidgets);
    expect(
      find.text('Les planifiées ne sont pas encore sorties de tes comptes.'),
      findsOneWidget,
    );
    expect(find.textContaining('Aujourd'), findsOneWidget);

    // Recherche derrière la loupe.
    await tester.tap(find.byTooltip('Rechercher'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'boulangerie');
    await tester.pumpAndSettle();
    expect(find.text('Aucun résultat'), findsOneWidget);
    await tester.tap(find.byTooltip('Fermer la recherche'));
    await tester.pumpAndSettle();
    expect(find.text('Transport · Wave'), findsOneWidget);

    // Semaine puis jour : toujours l'opération d'aujourd'hui.
    await tester.tap(find.text('Semaine'));
    await tester.pumpAndSettle();
    expect(find.text('9 nov. – 15 nov.'), findsOneWidget);
    expect(find.text('Transport · Wave'), findsOneWidget);
    await tester.tap(find.byTooltip('Période précédente'));
    await tester.pumpAndSettle();
    expect(find.text('Rien sur cette période'), findsOneWidget);
    await tester.tap(find.text('Jour'));
    await tester.pumpAndSettle();
    expect(find.text('Lundi 2 nov.'), findsOneWidget);
  });
}
