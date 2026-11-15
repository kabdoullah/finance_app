import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// Base SQLite unique de l'application (source de vérité).
///
/// Les tables seront ajoutées fonctionnalité par fonctionnalité. Toute
/// modification du schéma après une version publiée passe par une migration
/// (`dart run drift_dev make-migrations`) testée.
@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // SQLite désactive les clés étrangères par défaut.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
