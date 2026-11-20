import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/assistant/data/ai_platform.dart';
import 'package:finance_app/features/assistant/data/assistant_history_repository.dart';
import 'package:finance_app/features/assistant/domain/assistant_reply.dart';
import 'package:finance_app/features/assistant/presentation/assistant_controller.dart';
import 'package:finance_app/features/assistant/presentation/assistant_page.dart';
import 'package:finance_app/features/quick_entry/domain/quick_entry_parser.dart';
import 'package:finance_app/features/transactions/data/transactions_repository.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/features/transactions/domain/transaction_draft.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fake_ai.dart';
import '../../helpers/test_app.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDatabase();
    final wave = switch (await AccountsRepository(db, () => testNow).create(
      const AccountDraft(
        type: AccountType.mobileMoney,
        name: 'Wave',
        openingBalance: Money(100000),
      ),
    )) {
      Ok<Account>(:final value) => value,
      Err(:final failure) => fail('$failure'),
    };
    final transactions = TransactionsRepository(db, () => testNow);
    for (final (amount, category, day) in [
      (17000, 'exp.food', 10),
      (11000, 'exp.transport', 12),
    ]) {
      await transactions.create(
        TransactionDraft(
          kind: TransactionKind.expense,
          amount: Money(amount),
          occurredAt: DateTime(2026, 11, day, 12),
          accountId: wave.id,
          categoryId: category,
        ),
      );
    }
  });
  tearDown(() => db.close());

  /// Application avec un faux Gemma installé, chargé ou non, puis onglet
  /// Assistant.
  Future<FakeModel> openAssistant(
    WidgetTester tester, {
    bool compatible = true,
    bool loaded = true,
    String? answer,
    FunctionCallResponse? toolCall,
  }) async {
    final model = FakeModel(answer: answer, toolCall: toolCall);
    await pumpTestApp(
      tester,
      db,
      overrides: [
        deviceInfoServiceProvider.overrideWithValue(
          FakeDeviceInfo(
            compatible ? fakeDevice() : fakeDevice(is64Bit: false),
          ),
        ),
        gemmaRuntimeProvider.overrideWithValue(
          FakeGemmaRuntime(installed: true, model: model),
        ),
        aiPreferencesProvider.overrideWithValue(
          FakeAiPreferences(value: loaded),
        ),
      ],
    );
    await tester.tap(find.text('Assistant').last);
    await tester.pumpAndSettle();
    return model;
  }

  Future<void> ask(WidgetTester tester, String question) async {
    await tester.enterText(find.byType(TextField), question);
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();
  }

  const weekSpending = FunctionCallResponse(
    name: 'get_spending',
    args: {'period': 'this_week'},
  );

  testWidgets('question : chiffres de l\'application expliqués par Gemma', (
    tester,
  ) async {
    final model = await openAssistant(
      tester,
      answer:
          'Tu as dépensé 28 000 FCFA cette semaine, surtout en '
          'alimentation.',
      toolCall: weekSpending,
    );
    await ask(tester, 'Quelle catégorie me coûte le plus ?');

    expect(model.lastChat!.queries, ['Quelle catégorie me coûte le plus ?']);
    expect(model.lastChat!.toolResults.single['total_fcfa'], 28000);
    expect(
      find.textContaining('Tu as dépensé 28 000 FCFA cette semaine, surtout'),
      findsOneWidget,
    );
    expect(find.text('Alimentation'), findsOneWidget);
    expect(find.text('17 000 FCFA'), findsOneWidget);
    expect(
      find.text('Chiffres calculés par l\'application · expliqués par Gemma 4'),
      findsOneWidget,
    );
    expect(find.text('Voir les opérations'), findsOneWidget);
  });

  testWidgets('chiffre inventé par Gemma : phrase de l\'application', (
    tester,
  ) async {
    await openAssistant(
      tester,
      answer: 'Tu as dépensé 99 000 FCFA cette semaine.',
      toolCall: weekSpending,
    );
    await ask(tester, 'Quelle catégorie me coûte le plus ?');
    expect(find.textContaining('99 000'), findsNothing);
    expect(
      find.textContaining('Tu as dépensé 28 000 FCFA cette semaine.'),
      findsOneWidget,
    );
  });

  testWidgets('assistant pas chargé : raccourcis et « Charger »', (
    tester,
  ) async {
    await openAssistant(tester, loaded: false);
    expect(find.text('L\'assistant n\'est pas chargé'), findsOneWidget);
    expect(find.text('Simuler un achat'), findsOneWidget);
    await tester.ensureVisible(find.text('Charger l\'assistant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Charger l\'assistant'));
    await tester.pumpAndSettle();
    expect(find.text('Pose ta question…'), findsOneWidget);
  });

  testWidgets('téléphone non compatible : pas de bouton de chargement', (
    tester,
  ) async {
    await openAssistant(tester, compatible: false);
    expect(
      find.textContaining('n\'est pas disponible sur ce téléphone'),
      findsOneWidget,
    );
    expect(find.text('Charger l\'assistant'), findsNothing);
    expect(find.text('Installer l\'assistant'), findsNothing);
  });

  testWidgets(
    'opération préparée : enregistrée seulement après « Enregistrer »',
    (tester) async {
      await openAssistant(
        tester,
        answer: 'C\'est noté.',
        toolCall: const FunctionCallResponse(
          name: 'prepare_operation',
          args: {'text': 'taxi'},
        ),
      );
      final before = (await db.select(db.transactions).get()).length;
      await tester.enterText(
        find.byType(TextField),
        'Taxi 2 500 ce matin avec Wave',
      );
      await tester.tap(find.byTooltip('Envoyer'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'J\'ai préparé cette opération. Vérifie avant d\'enregistrer :',
        ),
        findsOneWidget,
      );
      expect(find.text('\u22122\u00a0500 FCFA'), findsOneWidget);
      expect((await db.select(db.transactions).get()).length, before);

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      final rows = await db.select(db.transactions).get();
      expect(rows.length, before + 1);
      expect(rows.last.entryMethod, 'text');
      expect(rows.last.amount, 2500);
      // 100 000 − 17 000 − 11 000 − 2 500.
      expect(
        find.text('Dépense enregistrée · solde Wave : 69\u00a0500 FCFA'),
        findsOneWidget,
      );
      expect(find.text('Enregistrer'), findsNothing);
    },
  );

  testWidgets('question demandée ailleurs : posée à l\'ouverture', (
    tester,
  ) async {
    final model = FakeModel(answer: 'Rien à signaler.');
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
        aiPreferencesProvider.overrideWithValue(FakeAiPreferences(value: true)),
      ],
    );
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
        .read(assistantRequestProvider.notifier)
        .ask('Puis-je acheter Téléphone à 150 000 FCFA ?');
    await tester.tap(find.text('Assistant').last);
    await tester.pumpAndSettle();
    expect(find.byType(AssistantPage), findsOneWidget);
    expect(model.lastChat!.queries, [
      'Puis-je acheter Téléphone à 150 000 FCFA ?',
    ]);
  });

  group('historique', () {
    Future<void> seedHistory() async {
      final history = AssistantHistoryRepository(db, () => testNow);
      await history.add(const UserEntry('Taxi 2 500 avec Wave'));
      await history.add(
        ReplyEntry(
          text: 'J\'ai préparé cette opération.',
          prepared: [
            ParsedOperation(
              kind: TransactionKind.expense,
              amount: const Money(2500),
              categoryId: 'exp.transport',
              date: DateTime(2026, 11, 14),
              description: 'Taxi',
            ),
          ],
        ),
      );
    }

    testWidgets('réouverture : conversation affichée, carte non enregistrée', (
      tester,
    ) async {
      await seedHistory();
      await openAssistant(tester);
      expect(find.text('Taxi 2 500 avec Wave'), findsOneWidget);
      expect(find.text('Non enregistrée'), findsOneWidget);
      expect(find.text('Enregistrer'), findsNothing);
    });

    testWidgets('« Effacer l\'historique » dans les Paramètres', (
      tester,
    ) async {
      await seedHistory();
      await pumpTestApp(tester, db);
      await tester.tap(find.byTooltip('Paramètres'));
      await tester.pumpAndSettle();
      await tapSetting(tester, 'Effacer l\'historique de conversation');
      await tester.pumpAndSettle();
      expect(find.text('Effacer l\'historique ?'), findsOneWidget);
      await tester.tap(find.text('Effacer'));
      await tester.pumpAndSettle();
      expect(await db.select(db.assistantMessages).get(), isEmpty);
      expect(find.text('Historique effacé.'), findsOneWidget);
    });
  });
}
