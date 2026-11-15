import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_database.dart';
import 'database_connection.dart';
import 'database_key_store.dart';

final databaseKeyStoreProvider = Provider<DatabaseKeyStore>(
  (ref) => DatabaseKeyStore(const FlutterSecureStorage()),
);

/// Instance unique de la base. Dans les tests, remplacée par une base en
/// mémoire via `appDatabaseProvider.overrideWithValue(...)`.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(
    openEncryptedConnection(ref.watch(databaseKeyStoreProvider)),
  );
  ref.onDispose(database.close);
  return database;
});
