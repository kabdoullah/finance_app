import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finance_app/app/app.dart';
import 'package:finance_app/core/clock.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/database/database_providers.dart';
import 'package:finance_app/features/settings/presentation/settings_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Date fixe des tests : dimanche 15 novembre 2026, 9 h.
final testNow = DateTime(2026, 11, 15, 9);

/// Base en mémoire, sans minuteur résiduel en fin de test de widget.
AppDatabase newTestDatabase() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// Lance l'application sur un écran de téléphone (390 × 844, comme les
/// maquettes) et attend la fin des animations.
Future<void> pumpTestApp(
  WidgetTester tester,
  AppDatabase db, {
  List<Override> overrides = const [],
}) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(buildTestApp(db, overrides: overrides));
  await tester.pumpAndSettle();
}

/// Application complète sur [db] (pas de chiffrement ni de Keychain en test),
/// avec d'éventuels [overrides] en plus (ex. faux Gemma).
Widget buildTestApp(AppDatabase db, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => testNow),
        ...overrides,
      ],
      child: const FinanceApp(),
    );

/// Zone défilante de l'écran [page] (pages longues : les lignes du bas ne
/// sont construites qu'après défilement).
Finder scrollableOf(Type page) => find
    .descendant(of: find.byType(page), matching: find.byType(Scrollable))
    .first;

/// Fait défiler les Paramètres jusqu'à [text], puis le touche.
Future<void> tapSetting(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: scrollableOf(SettingsPage),
  );
  await tester.tap(find.text(text));
}
