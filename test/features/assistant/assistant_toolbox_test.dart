import 'dart:ui' show Locale;

import 'package:finance_app/core/clock.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/database/database_providers.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/assistant/data/assistant_toolbox.dart';
import 'package:finance_app/features/assistant/domain/assistant_reply.dart';
import 'package:finance_app/features/budgets/data/budgets_repository.dart';
import 'package:finance_app/features/budgets/domain/budget_draft.dart';
import 'package:finance_app/features/transactions/data/transactions_repository.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/features/transactions/domain/transaction_draft.dart';
import 'package:finance_app/l10n/l10n.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/test_app.dart';

final _toolboxProvider = Provider(
  (ref) => AssistantToolbox(ref, lookupAppLocalizations(const Locale('fr'))),
);

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late AssistantToolbox toolbox;
  late List<Tool> tools;

  setUpAll(() => initializeDateFormatting('fr'));

  setUp(() async {
    db = newTestDatabase();
    final accounts = AccountsRepository(db, () => testNow);
    Future<Account> account(String name, int balance) async =>
        switch (await accounts.create(
          AccountDraft(
            type: AccountType.mobileMoney,
            name: name,
            openingBalance: Money(balance),
          ),
        )) {
          Ok(:final value) => value,
          Err(:final failure) => fail('$failure'),
        };
    final wave = await account('Wave', 100000);
    await account('Orange Money', 20000);

    // testNow : dimanche 15 novembre 2026 ; la semaine commence le lundi 9.
    final transactions = TransactionsRepository(db, () => testNow);
    for (final (amount, category, at) in [
      (17000, 'exp.food.restaurant', DateTime(2026, 11, 10, 12)),
      (11000, 'exp.transport', DateTime(2026, 11, 12, 8)),
      (75000, 'exp.housing', DateTime(2026, 11, 1, 10)),
      (5000, 'exp.food', DateTime(2026, 10, 20, 10)),
    ]) {
      await transactions.create(
        TransactionDraft(
          kind: TransactionKind.expense,
          amount: Money(amount),
          occurredAt: at,
          accountId: wave.id,
          categoryId: category,
        ),
      );
    }
    await BudgetsRepository(
      db,
      () => testNow,
    ).create(const BudgetDraft(limit: Money(50000), categoryId: 'exp.food'));

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => testNow),
      ],
    );
    toolbox = container.read(_toolboxProvider);
    tools = await toolbox.prepare();
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('outils construits avec les codes des catégories et comptes', () {
    expect(tools.map((t) => t.name), [
      'get_spending',
      'get_budget_status',
      'get_balance',
      'get_forecast',
      'simulate_purchase',
      'prepare_operation',
      'get_savings_overview',
      'plan_savings_goal',
    ]);
    final balance = tools[2].parameters['properties'] as Map;
    expect((balance['account'] as Map)['enum'], ['orange_money', 'wave']);
  });

  test('dépenses de la semaine, réparties par catégorie', () async {
    final outcome = await toolbox.run('get_spending', {'period': 'this_week'});
    expect(outcome.data['total_fcfa'], 28000);
    expect(outcome.summary, contains('28 000 FCFA cette semaine'));
    expect(outcome.rows.map((r) => r.label), ['Alimentation', 'Transport']);
    expect(outcome.link?.target, ReplyLinkTarget.transactions);
    // Chiffre clé en tête de la réponse (maquette).
    expect(outcome.head?.value, '28\u00a0000 FCFA');
    expect(outcome.head?.caption, 'dépensés cette semaine');
  });

  test('dépenses d\'une catégorie ce mois-ci, par sous-catégorie', () async {
    final outcome = await toolbox.run('get_spending', {
      'period': 'this_month',
      'category': 'alimentation',
    });
    expect(outcome.data['total_fcfa'], 17000);
    expect(outcome.rows.single.label, 'Restaurant');
  });

  test('mois dernier', () async {
    final outcome = await toolbox.run('get_spending', {'period': 'last_month'});
    expect(outcome.data['total_fcfa'], 5000);
  });

  test('budgets : reste, jours restants, possible sur 7 jours', () async {
    final outcome = await toolbox.run('get_budget_status', {});
    // 50 000 − 17 000 = 33 000 sur 16 jours (15 → 30 nov. inclus).
    expect(outcome.data['remaining_fcfa'], 33000);
    expect(outcome.data['days_left'], 16);
    expect(outcome.data['per_day_fcfa'], 2000);
    expect(outcome.data['next_7_days_fcfa'], 14000);
    expect(outcome.head?.value, '14\u00a0000 FCFA');
    expect(
      outcome.head?.caption,
      'à dépenser sur 7 jours, soit 2\u00a0000\u00a0FCFA par jour',
    );
    expect(outcome.rows.map((r) => r.value), [
      '33 000 FCFA',
      '16',
      '14 000 FCFA',
    ]);
  });

  test('budget d\'une catégorie sans budget', () async {
    final outcome = await toolbox.run('get_budget_status', {
      'category': 'transport',
    });
    expect(outcome.data['budget'], 'none');
    expect(outcome.rows, isEmpty);
  });

  test('soldes', () async {
    final all = await toolbox.run('get_balance', {});
    // Wave : 100 000 − 108 000 ; Orange Money : 20 000.
    expect(all.data['total_fcfa'], 12000);
    expect(all.head?.caption, 'sur tes comptes aujourd\'hui');
    final orange = await toolbox.run('get_balance', {
      'account': 'orange_money',
    });
    expect(orange.summary, 'Tu as 20 000 FCFA sur Orange Money.');
  });

  test('prévision et simulation d\'achat', () async {
    // Première opération le 20 oct. : 26 jours d'historique, assez.
    final forecast = await toolbox.run('get_forecast', {'days': 30});
    expect(forecast.data, contains('expected_balance_fcfa'));
    expect(forecast.link?.target, ReplyLinkTarget.forecast);

    final simulation = await toolbox.run('simulate_purchase', {
      'label': 'Téléphone',
      'price': 150000,
    });
    expect(simulation.data['verdict'], 'discouraged');
    expect(simulation.link?.simulationPrice, 150000);
    expect(simulation.link?.simulationLabel, 'Téléphone');
  });

  test('opération préparée depuis la phrase de l\'utilisateur', () async {
    toolbox.question = 'Taxi 2 500 ce matin avec Wave';
    final outcome = await toolbox.run('prepare_operation', {
      // Reformulation de Gemma ignorée.
      'text': 'taxi 9 999',
    });
    expect(outcome.prepared, hasLength(1));
    expect(outcome.prepared.single.amount, const Money(2500));
    expect(outcome.data['prepared'], 1);
    expect(outcome.rows, isEmpty);

    toolbox.question = 'bonjour';
    final none = await toolbox.run('prepare_operation', {});
    expect(none.prepared, isEmpty);
    expect(none.summary, startsWith('Je n\'ai pas trouvé de montant'));
  });

  test('bilan d\'épargne : moins d\'un mois d\'historique', () async {
    final outcome = await toolbox.run('get_savings_overview', {});
    expect(outcome.data['savings'], 'not_enough_history');
    expect(outcome.rows, isEmpty);
  });

  test('objectif : 100 000 en 3 mois', () async {
    final outcome = await toolbox.run('plan_savings_goal', {
      'amount': 100000,
      'months': 3,
      'label': 'Moto',
    });
    // 33 333,33 arrondi à la centaine supérieure.
    expect(outcome.data['monthly_fcfa'], 33400);
    expect(outcome.rows.first.value, '33\u00a0400 FCFA');
    expect(outcome.link?.target, ReplyLinkTarget.goal);
    expect(outcome.link?.goalMonths, 3);
    expect(outcome.link?.goalTarget, 100000);
    expect(outcome.link?.goalName, 'Moto');
  });
}
