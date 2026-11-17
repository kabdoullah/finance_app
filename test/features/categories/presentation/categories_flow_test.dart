import 'package:finance_app/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  Future<void> openCategories(WidgetTester tester) async {
    await pumpTestApp(tester, db);
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catégories'));
    await tester.pumpAndSettle();
  }

  testWidgets('créer puis supprimer une catégorie personnalisée', (
    tester,
  ) async {
    await openCategories(tester);
    expect(find.text('Alimentation'), findsOneWidget);

    await tester.tap(find.byTooltip('Nouvelle catégorie'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Moto');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer la catégorie'));
    await tester.pumpAndSettle();

    expect(find.text('Catégorie « Moto » créée.'), findsOneWidget);
    // Le message de confirmation se ferme seul ; il masquerait la liste.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Moto'), 200);
    expect(find.text('Personnalisée'), findsOneWidget);

    await tester.tap(find.text('Moto'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Supprimer'));
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer « Moto » ?'), findsOneWidget);
    expect(
      find.textContaining('Aucune opération ne l\'utilise.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();

    expect(find.text('Catégorie supprimée.'), findsOneWidget);
    expect(find.text('Moto'), findsNothing);
  });

  testWidgets('masquer une catégorie prédéfinie (pas de suppression)', (
    tester,
  ) async {
    await openCategories(tester);

    await tester.tap(find.text('Loisirs'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer'), findsNothing);
    expect(find.text('Renommer'), findsNothing);

    await tester.tap(find.text('Masquer'));
    await tester.pumpAndSettle();
    expect(find.text('Masquée'), findsOneWidget);
    expect(find.text('Réafficher'), findsOneWidget);
  });
}
