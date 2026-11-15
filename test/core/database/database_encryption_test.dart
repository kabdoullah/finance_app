import 'dart:convert';
import 'dart:io';

import 'package:finance_app/core/database/database_connection.dart';
import 'package:finance_app/core/database/database_key_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Vérifie le chiffrement réel avec le moteur SQLite3MultipleCiphers fourni
/// par les hooks de build (même configuration que l'application).
void main() {
  late Directory tempDir;
  late String path;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('finance_app_db_');
    path = '${tempDir.path}/test.db';
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  Database openWithKey(String key) {
    final db = sqlite3.open(path);
    try {
      applyEncryptionKey(db, key);
    } catch (_) {
      db.close();
      rethrow;
    }
    return db;
  }

  test('le fichier écrit sur disque est chiffré et relisible avec la clé', () {
    final key = DatabaseKeyStore.generateKey();

    openWithKey(key)
      ..execute('CREATE TABLE notes (body TEXT NOT NULL)')
      ..execute("INSERT INTO notes VALUES ('solde secret')")
      ..close();

    final raw = File(path).readAsBytesSync();
    expect(
      ascii.decode(raw.sublist(0, 15), allowInvalid: true),
      isNot('SQLite format 3'),
    );
    expect(latin1.decode(raw).contains('solde secret'), isFalse);

    final reopened = openWithKey(key);
    addTearDown(reopened.close);
    expect(
      reopened.select('SELECT body FROM notes').single['body'],
      'solde secret',
    );
  });

  test('une mauvaise clé est refusée à l’ouverture', () {
    openWithKey(DatabaseKeyStore.generateKey())
      ..execute('CREATE TABLE t (x INTEGER)')
      ..close();

    expect(
      () => openWithKey(DatabaseKeyStore.generateKey()),
      throwsA(isA<SqliteException>()),
    );
  });

  test('une clé au format inattendu est rejetée', () {
    final db = sqlite3.open(path);
    addTearDown(db.close);

    expect(
      () => applyEncryptionKey(db, "x'; DROP TABLE t; --"),
      throwsArgumentError,
    );
  });
}
