import 'package:finance_app/app/app.dart';
import 'package:finance_app/core/database/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Tests sur appareil réel ou simulateur : `flutter test integration_test`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    "l'application démarre sur l'accueil, avec sa base chiffrée migrée",
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: FinanceApp()));

      // Sur appareil, l'ouverture de la base (Keychain/Keystore, isolate,
      // migrations) prend plusieurs frames : on attend l'accueil, 10 s max.
      final balance = find.text('Solde total');
      for (var i = 0; i < 100 && balance.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(balance, findsOneWidget);

      // Même instance de base que l'application (un seul ProviderScope).
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FinanceApp)),
      );
      final db = container.read(appDatabaseProvider);
      final engine = await db
          .customSelect('SELECT sqlite3mc_version() AS v')
          .getSingle();
      expect(engine.read<String>('v'), startsWith('SQLite3 Multiple Ciphers'));
      // Les tables des migrations (v2, v3) existent et se lisent sur
      // l'appareil ; les catégories par défaut ont été insérées.
      await db.select(db.accounts).get();
      await db.select(db.transactions).get();
      expect(await db.select(db.categories).get(), isNotEmpty);
    },
  );
}
