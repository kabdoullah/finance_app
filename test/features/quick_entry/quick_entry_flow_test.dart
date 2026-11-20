import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/assistant/data/ai_platform.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fake_ai.dart';
import '../../helpers/test_app.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDatabase();
    final accounts = AccountsRepository(db, () => testNow);
    for (final (name, type) in [
      ('Wave', AccountType.mobileMoney),
      ('Orange Money', AccountType.mobileMoney),
      ('Espèces', AccountType.cash),
    ]) {
      await accounts.create(
        AccountDraft(type: type, name: name, openingBalance: Money(50000)),
      );
    }
  });
  tearDown(() => db.close());

  Future<void> openSheet(WidgetTester tester) async {
    await pumpTestApp(tester, db);
    await tester.tap(find.byTooltip('Ajouter').last);
    await tester.pumpAndSettle();
  }

  testWidgets('écrire deux opérations, vérifier, enregistrer', (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('Écrire avec mes mots'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'Hier, 2 000 de crédit Orange et 1 500 de pain en espèces',
    );
    await tester.pump();
    await tester.tap(find.text('Analyser'));
    await tester.pumpAndSettle();

    expect(find.text('2 opérations détectées'), findsOneWidget);
    expect(
      find.text('Rien n\'est enregistré avant ta confirmation.'),
      findsOneWidget,
    );
    // Total des dépenses : 3 500.
    expect(find.text('−3 500 FCFA'), findsOneWidget);

    await tester.tap(find.text('Enregistrer 2 opérations'));
    await tester.pumpAndSettle();
    expect(find.text('2 opérations enregistrées'), findsOneWidget);

    final rows = await db.select(db.transactions).get();
    expect(rows, hasLength(2));
    expect(rows.map((r) => r.entryMethod), everyElement('text'));
    expect(rows.map((r) => r.amount).toSet(), {2000, 1500});
    for (final row in rows) {
      final day = DateTime.fromMillisecondsSinceEpoch(row.occurredAt);
      expect((day.year, day.month, day.day), (2026, 11, 14));
    }
  });

  testWidgets('rien n\'est enregistré tant qu\'un montant manque', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.tap(find.text('Écrire avec mes mots'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'taxi wave');
    await tester.pump();
    await tester.tap(find.text('Analyser'));
    await tester.pumpAndSettle();

    expect(find.text('1 opération détectée'), findsOneWidget);
    final save = find.widgetWithText(FilledButton, 'Enregistrer l\'opération');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, '2500');
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
  });

  testWidgets('sans dictée hors ligne : bascule sur le clavier', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('finance_app/speech'),
      (call) async => call.method == 'status' ? 'unsupported' : null,
    );
    await openSheet(tester);
    await tester.tap(find.text('Dicter').last);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('La dictée hors connexion n\'est pas disponible'),
      findsOneWidget,
    );
    expect(find.text('Analyser'), findsOneWidget);
  });

  group('avec Gemma', () {
    /// Lance l'application avec un faux Gemma installé ([loaded] : chargé dès
    /// le démarrage) qui répond [answer], puis écrit [text] et analyse.
    Future<FakeModel> analyseWithAi(
      WidgetTester tester,
      String text, {
      required bool loaded,
      String? answer,
    }) async {
      final model = FakeModel(answer: answer);
      await pumpTestApp(
        tester,
        db,
        overrides: [
          deviceInfoServiceProvider.overrideWithValue(
            FakeDeviceInfo(fakeDevice()),
          ),
          gemmaRuntimeProvider.overrideWithValue(
            FakeGemmaRuntime(installed: true, model: model),
          ),
          aiPreferencesProvider.overrideWithValue(
            FakeAiPreferences(value: loaded),
          ),
        ],
      );
      await tester.tap(find.byTooltip('Ajouter').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Écrire avec mes mots'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
      await tester.tap(find.text('Analyser'));
      return model;
    }

    testWidgets(
      'Gemma complète les champs incertains, qui restent à vérifier',
      (tester) async {
        final model = await analyseWithAi(
          tester,
          'déj 2500',
          loaded: true,
          answer:
              '{"kind":"expense","amount":2500,"category":"alimentation",'
              '"account":"orange_money"}',
        );
        await tester.pumpAndSettle();
        expect(model.lastChat!.queries, ['déj 2500']);
        expect(model.lastChat!.closed, isTrue);
        expect(find.text('1 opération détectée'), findsOneWidget);
        expect(find.text('À vérifier'), findsWidgets);
        expect(find.text('Gérer le modèle IA'), findsNothing);

        await tester.tap(find.text('Enregistrer l\'opération'));
        await tester.pumpAndSettle();
        final row = (await db.select(db.transactions).get()).single;
        expect(row.categoryId, 'exp.food');
        final orange = await (db.select(
          db.accounts,
        )..where((a) => a.name.equals('Orange Money'))).getSingle();
        expect(row.accountId, orange.id);
      },
    );

    testWidgets('« Passer » : récapitulatif de l\'analyseur seul', (
      tester,
    ) async {
      // Gemma ne répond jamais.
      await analyseWithAi(tester, 'déj 2500', loaded: true);
      await tester.pump();
      await tester.pump();
      expect(
        find.text('Gemma 4 repère les montants, catégories et comptes…'),
        findsOneWidget,
      );
      await tester.tap(find.text('Passer'));
      await tester.pump();
      expect(find.text('1 opération détectée'), findsOneWidget);
      // Fin du délai de 30 s laissé à Gemma.
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(find.text('1 opération détectée'), findsOneWidget);
    });

    testWidgets('modèle installé mais pas chargé : lien vers le modèle', (
      tester,
    ) async {
      await analyseWithAi(tester, 'déj 2500', loaded: false);
      await tester.pumpAndSettle();
      expect(find.textContaining('Assistant IA indisponible.'), findsOneWidget);
      await tester.tap(find.text('Gérer le modèle IA'));
      await tester.pumpAndSettle();
      expect(find.text('Modèle IA'), findsOneWidget);
      expect(find.text('Charger maintenant'), findsOneWidget);
    });
  });
}
