import 'package:finance_app/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

const _nnbsp = '\u00a0';

void main() {
  late AppDatabase db;

  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  Future<void> createWave(WidgetTester tester, {String balance = '15000'}) async {
    await tester.tap(find.text('Mobile Money'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wave'));
    await tester.enterText(find.byType(TextField).last, balance);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer le compte'));
    await tester.pumpAndSettle();
  }

  testWidgets('créer un premier compte depuis l’accueil', (tester) async {
    await pumpTestApp(tester, db);

    await tester.tap(find.text('Ajoute tes comptes'));
    await tester.pumpAndSettle();
    expect(find.text('Nouveau compte'), findsOneWidget);
    // Le bouton reste inactif tant que le type et le nom manquent.
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await createWave(tester);

    expect(find.text('Compte « Wave » créé'), findsOneWidget);
    expect(find.textContaining('15${_nnbsp}000'), findsOneWidget);

    await tester.tap(find.text('Voir mes comptes'));
    await tester.pumpAndSettle();

    expect(find.text('Mes comptes'), findsOneWidget);
    expect(find.text('1 compte'), findsOneWidget);
    expect(find.text('MOBILE MONEY'), findsOneWidget);
    expect(find.text('Ajouter un compte épargne'), findsOneWidget);

    // Retour à l'accueil : solde réel et étape 1 cochée.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Solde total · 1 compte'), findsOneWidget);
    expect(find.text('15${_nnbsp}000'), findsOneWidget);
  });

  testWidgets('un nom déjà utilisé est refusé', (tester) async {
    await pumpTestApp(tester, db);
    await tester.tap(find.text('Ajoute tes comptes'));
    await tester.pumpAndSettle();
    await createWave(tester);
    await tester.tap(find.text('Ajouter un autre compte'));
    await tester.pumpAndSettle();

    await createWave(tester, balance: '0');

    expect(find.text('Tu as déjà un compte actif à ce nom.'), findsOneWidget);
  });

  testWidgets('archiver puis restaurer un compte', (tester) async {
    await pumpTestApp(tester, db);
    await tester.tap(find.text('Ajoute tes comptes'));
    await tester.pumpAndSettle();
    await createWave(tester);
    await tester.tap(find.text('Voir mes comptes'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wave'));
    await tester.pumpAndSettle();
    expect(find.text('Mobile Money · Wave'), findsOneWidget);
    expect(find.textContaining('saisi le 15 nov. 2026'), findsOneWidget);

    await tester.tap(find.text('Archiver ce compte'));
    await tester.pumpAndSettle();
    expect(find.text('Archiver le compte Wave ?'), findsOneWidget);
    await tester.tap(find.text('Archiver'));
    await tester.pumpAndSettle();

    // Retour à la liste : total à 0, compte dans les archivés.
    expect(find.text('Aucun compte'), findsOneWidget);
    expect(find.text('ARCHIVÉS'), findsOneWidget);

    await tester.tap(find.text('Wave'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restaurer ce compte'));
    await tester.pumpAndSettle();
    expect(find.text('Compte restauré.'), findsOneWidget);
    expect(find.text('Archiver ce compte'), findsOneWidget);
  });

  testWidgets('supprimer un compte après confirmation', (tester) async {
    await pumpTestApp(tester, db);
    await tester.tap(find.text('Ajoute tes comptes'));
    await tester.pumpAndSettle();
    await createWave(tester);
    await tester.tap(find.text('Voir mes comptes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wave'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Supprimer ce compte'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Ton solde total baissera de 15${_nnbsp}000'),
      findsOneWidget,
    );
    await tester.tap(find.text('Supprimer définitivement'));
    await tester.pumpAndSettle();

    expect(find.text('Mes comptes'), findsOneWidget);
    expect(find.text('Aucun compte pour l\'instant.'), findsOneWidget);
  });
}
