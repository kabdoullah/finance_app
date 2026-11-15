import 'package:drift/drift.dart';

import '../../features/accounts/data/accounts_table.dart';
import 'app_database.steps.dart';

part 'app_database.g.dart';

/// Base SQLite unique de l'application (source de vérité).
///
/// Les tables seront ajoutées fonctionnalité par fonctionnalité. Toute
/// modification du schéma après une version publiée passe par une migration
/// (`dart run drift_dev make-migrations`) testée.
@DriftDatabase(tables: [Accounts])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Une étape par version, sur le schéma figé de chaque version
    // (drift_schemas/), pour que les anciennes migrations ne bougent jamais.
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.createTable(schema.accounts);
        await m.createIndex(schema.accountsActiveNameUnique);
      },
    ),
    beforeOpen: (details) async {
      // SQLite désactive les clés étrangères par défaut.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
