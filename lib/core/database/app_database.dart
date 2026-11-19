import 'package:drift/drift.dart';

import '../../features/accounts/data/accounts_table.dart';
import '../../features/assistant/data/assistant_messages_table.dart';
import '../../features/budgets/data/budgets_table.dart';
import '../../features/categories/data/categories_table.dart';
import '../../features/categories/data/default_categories.dart';
import '../../features/goals/data/goals_tables.dart';
import '../../features/recurring/data/recurring_table.dart';
import '../../features/transactions/data/transactions_table.dart';
import 'app_database.steps.dart';

part 'app_database.g.dart';

/// Base SQLite unique de l'application (source de vérité).
///
/// Les tables sont ajoutées fonctionnalité par fonctionnalité. Toute
/// modification du schéma passe par une migration
/// (`dart run drift_dev make-migrations`) testée.
@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Transactions,
    Budgets,
    RecurringOperations,
    SavingsGoals,
    GoalMovements,
    AssistantMessages,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await insertDefaultCategories(this, _nowMs());
    },
    // Une étape par version, sur le schéma figé de chaque version
    // (drift_schemas/), pour que les anciennes migrations ne bougent jamais.
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.createTable(schema.accounts);
        await m.createIndex(schema.accountsActiveNameUnique);
      },
      from2To3: (m, schema) async {
        await m.createTable(schema.categories);
        await m.createTable(schema.transactions);
        await m.createIndex(schema.transactionsAccount);
        await m.createIndex(schema.transactionsToAccount);
        await m.createIndex(schema.transactionsOccurredAt);
        await insertDefaultCategories(this, _nowMs());
      },
      from3To4: (m, schema) async {
        await m.addColumn(schema.categories, schema.categories.isCustom);
        await m.addColumn(schema.categories, schema.categories.hiddenAt);
      },
      from4To5: (m, schema) async {
        await m.createTable(schema.budgets);
        await m.createIndex(schema.budgetsCategoryUnique);
      },
      from5To6: (m, schema) async {
        await m.createTable(schema.recurringOperations);
        await m.createIndex(schema.recurringNextDue);
        await m.addColumn(schema.transactions, schema.transactions.recurringId);
      },
      from6To7: (m, schema) async {
        await m.createTable(schema.savingsGoals);
        await m.createTable(schema.goalMovements);
        await m.createIndex(schema.goalMovementsGoal);
        await m.createIndex(schema.goalMovementsAccount);
      },
      from7To8: (m, schema) async {
        await m.createTable(schema.assistantMessages);
        await m.createIndex(schema.assistantMessagesCreated);
      },
    ),
    beforeOpen: (details) async {
      // SQLite désactive les clés étrangères par défaut.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static int _nowMs() => DateTime.now().toUtc().millisecondsSinceEpoch;
}
