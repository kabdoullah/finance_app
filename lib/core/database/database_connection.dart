import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:sqlite3/common.dart';

import 'database_key_store.dart';

/// Nom du fichier de base, indépendant du nom (provisoire) de l'application.
const databaseName = 'app_database';

final _safeKey = RegExp(r'^[A-Za-z0-9_-]{32,}$');

/// Ouvre la base chiffrée. La clé est lue au premier accès à la base.
QueryExecutor openEncryptedConnection(DatabaseKeyStore keyStore) {
  return LazyDatabase(() async {
    final key = await keyStore.readOrCreateKey();
    return driftDatabase(
      name: databaseName,
      native: DriftNativeOptions(setup: (db) => applyEncryptionKey(db, key)),
    );
  });
}

/// Applique la clé de chiffrement juste après l'ouverture du fichier.
///
/// Échoue explicitement si le moteur n'est pas SQLite3MultipleCiphers : avec
/// un SQLite standard, `PRAGMA key` serait ignoré sans erreur et la base
/// serait écrite en clair.
void applyEncryptionKey(CommonDatabase db, String key) {
  if (!_safeKey.hasMatch(key)) {
    throw ArgumentError('Clé de chiffrement invalide.');
  }
  // La clé doit être appliquée avant toute autre requête : sur un fichier déjà
  // chiffré, préparer une requête lit le schéma et échoue sans clé.
  db.execute("PRAGMA key = '$key'");
  try {
    db.select('SELECT sqlite3mc_version()');
  } on SqliteException catch (e) {
    if (e.message.contains('no such function')) {
      throw StateError(
        'SQLite3MultipleCiphers est requis (hooks.user_defines.sqlite3.source: '
        'sqlite3mc dans pubspec.yaml).',
      );
    }
    rethrow;
  }
  // Lecture de contrôle : échoue immédiatement si la clé ne correspond pas.
  db.select('SELECT count(*) FROM sqlite_master');
}
