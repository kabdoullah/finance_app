import 'package:finance_app/app/app.dart';
import 'package:finance_app/core/database/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Tests sur appareil réel ou simulateur : `flutter test integration_test`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("l'application démarre sur l'accueil", (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FinanceApp()));
    await tester.pumpAndSettle();

    expect(find.text('Solde total'), findsOneWidget);
  });

  testWidgets(
    'la base chiffrée s’ouvre sur l’appareil (stockage sécurisé + sqlite3mc)',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final db = container.read(appDatabaseProvider);
      final row = await db
          .customSelect('SELECT sqlite3mc_version() AS v')
          .getSingle();

      expect(row.read<String>('v'), isNotEmpty);
    },
  );
}
