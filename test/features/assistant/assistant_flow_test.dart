import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/assistant/data/ai_platform.dart';
import 'package:finance_app/features/transactions/data/transactions_repository.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/features/transactions/domain/transaction_draft.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_test/flutter_test.dart';

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
    await tester.tap(find.text('Combien ai-je dépensé cette semaine ?'));
    await tester.pumpAndSettle();

    expect(model.lastChat!.queries, ['Combien ai-je dépensé cette semaine ?']);
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
    await tester.tap(find.text('Combien ai-je dépensé cette semaine ?'));
    await tester.pumpAndSettle();
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
}
