import 'package:finance_app/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  Widget buildApp() => buildTestApp(db);

  testWidgets("affiche l'accueil vide au démarrage", (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue'), findsOneWidget);
    expect(find.text('Dimanche 15 novembre'), findsOneWidget);
    expect(find.text('Solde total'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('FCFA'), findsOneWidget);
    expect(find.text('Pour bien démarrer'), findsOneWidget);
  });

  testWidgets('la barre basse change d’onglet', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Assistant'));
    await tester.pumpAndSettle();

    expect(find.text('Copilote'), findsOneWidget);
    expect(find.text('Solde total'), findsNothing);

    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();

    expect(find.text('Solde total'), findsOneWidget);
  });

  testWidgets("« Écrire au Copilote » ouvre l'onglet Assistant", (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Écrire au Copilote'));
    await tester.tap(find.text('Écrire au Copilote'));
    await tester.pumpAndSettle();

    // Écran du Copilote (sans IA en test : « pas chargé »).
    expect(find.text('Copilote'), findsOneWidget);
    expect(find.text('L\'assistant n\'est pas chargé'), findsOneWidget);
  });

  testWidgets('le bouton Paramètres ouvre un écran avec retour', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Paramètres'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Solde total'), findsOneWidget);
  });
}
