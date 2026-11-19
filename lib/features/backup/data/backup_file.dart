import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show immutable;
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_connection.dart';

/// Pourquoi une sauvegarde ne peut pas être lue.
enum BackupError {
  /// Mauvais mot de passe, ou fichier qui n'est pas une sauvegarde.
  unreadable,

  /// Sauvegarde faite par une version plus récente de l'application.
  tooNew,
}

class BackupException implements Exception {
  const BackupException(this.error);

  final BackupError error;

  @override
  String toString() => 'BackupException($error)';
}

/// Contenu d'une sauvegarde, lu avant de la restaurer.
@immutable
class BackupInfo {
  const BackupInfo({required this.createdAt, required this.schemaVersion});

  final DateTime createdAt;
  final int schemaVersion;
}

/// Fichier de sauvegarde : une copie de la base (VACUUM INTO, déjà chiffrée
/// par la clé du téléphone) rechiffrée avec le mot de passe choisi
/// (SQLite3MultipleCiphers, qui dérive lui-même la clé du mot de passe).
/// Sans ce mot de passe, la sauvegarde est illisible.
abstract final class BackupFile {
  static const minPasswordLength = 8;
  static const extension = 'fcbak';

  static const _infoTable = 'backup_info';

  /// Crée la sauvegarde de [db] (clé du téléphone [deviceKey]) dans
  /// [workDir] et retourne son contenu.
  static Future<Uint8List> create({
    required AppDatabase db,
    required String deviceKey,
    required String password,
    required Directory workDir,
    required DateTime now,
  }) async {
    final copy = _tempFile(workDir, 'backup');
    try {
      await db.customStatement('VACUUM INTO ${_quote(copy.path)}');
      final file = sqlite3.open(copy.path);
      try {
        applyEncryptionKey(file, deviceKey);
        file
          ..execute(
            'CREATE TABLE $_infoTable (created_at INTEGER NOT NULL, '
            'schema_version INTEGER NOT NULL)',
          )
          ..execute('INSERT INTO $_infoTable VALUES (?, ?)', [
            now.toUtc().millisecondsSinceEpoch,
            db.schemaVersion,
          ])
          ..execute('PRAGMA rekey = ${_quote(password)}');
      } finally {
        file.close();
      }
      return await copy.readAsBytes();
    } finally {
      _discard(copy);
    }
  }

  /// Lit [bytes] avec [password] ; lève [BackupException] sinon.
  static Future<BackupInfo> inspect({
    required Uint8List bytes,
    required String password,
    required Directory workDir,
    required int currentSchema,
  }) async {
    final file = await _write(bytes, workDir);
    try {
      return _readInfo(file.path, password, currentSchema);
    } finally {
      _discard(file);
    }
  }

  /// Prépare [bytes] pour remplacer la base : vérifié, informations retirées,
  /// rechiffré avec la clé du téléphone. Retourne le fichier prêt.
  static Future<File> prepareRestore({
    required Uint8List bytes,
    required String password,
    required String deviceKey,
    required Directory workDir,
    required int currentSchema,
  }) async {
    final file = await _write(bytes, workDir);
    try {
      _readInfo(file.path, password, currentSchema);
      final db = sqlite3.open(file.path);
      try {
        db
          ..execute('PRAGMA key = ${_quote(password)}')
          ..execute('DROP TABLE $_infoTable')
          ..execute('PRAGMA rekey = ${_quote(deviceKey)}');
      } finally {
        db.close();
      }
      return file;
    } on Object {
      _discard(file);
      rethrow;
    }
  }

  static BackupInfo _readInfo(String path, String password, int currentSchema) {
    final db = sqlite3.open(path);
    try {
      final BackupInfo info;
      try {
        db.execute('PRAGMA key = ${_quote(password)}');
        final row = db
            .select('SELECT created_at, schema_version FROM $_infoTable')
            .first;
        info = BackupInfo(
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            row['created_at'] as int,
            isUtc: true,
          ).toLocal(),
          schemaVersion: row['schema_version'] as int,
        );
      } on Object {
        throw const BackupException(BackupError.unreadable);
      }
      if (info.schemaVersion > currentSchema) {
        throw const BackupException(BackupError.tooNew);
      }
      return info;
    } finally {
      db.close();
    }
  }

  static Future<File> _write(Uint8List bytes, Directory workDir) async {
    final file = _tempFile(workDir, 'restore');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static File _tempFile(Directory workDir, String prefix) => File(
    p.join(
      workDir.path,
      '$prefix-${DateTime.now().microsecondsSinceEpoch}.tmp',
    ),
  );

  /// Supprime un fichier de travail temporaire.
  static void _discard(File file) {
    if (file.existsSync()) file.deleteSync();
  }

  /// Littéral SQL : guillemets simples doublés.
  static String _quote(String value) => "'${value.replaceAll("'", "''")}'";
}
