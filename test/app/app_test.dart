import 'package:finance_app/app/app.dart';
import 'package:finance_app/core/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Application complète avec une date fixe (dimanche 15 novembre 2026).
Widget buildApp() => ProviderScope(
  overrides: [clockProvider.overrideWithValue(() => DateTime(2026, 11, 15))],
  child: const FinanceApp(),
);

void main() {
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

    await tester.tap(find.text('Budgets'));
    await tester.pumpAndSettle();

    expect(find.text('Cet écran arrive bientôt.'), findsOneWidget);
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

    expect(find.text('Cet écran arrive bientôt.'), findsOneWidget);
    // Titre de l'écran + libellé de l'onglet.
    expect(find.text('Assistant'), findsNWidgets(2));
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
