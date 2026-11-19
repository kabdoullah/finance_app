import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import '../../../core/clock.dart';
import '../../../core/database/database_connection.dart' as connection;
import '../../../core/database/database_providers.dart';
import '../../../core/errors/error_reporter.dart';
import '../../../core/files/file_output.dart';
import '../data/backup_file.dart';
import '../data/database_swap.dart';

/// Emplacements et sélecteur de fichiers (remplacés dans les tests).
class BackupEnvironment {
  const BackupEnvironment([this._output = const FileOutput()]);

  final FileOutput _output;

  Future<Directory> workDir() => getTemporaryDirectory();

  Future<File> databaseFile() => connection.databaseFile();

  /// Enregistre [bytes] à l'emplacement choisi ; `false` si annulé.
  Future<bool> save(String fileName, Uint8List bytes) =>
      _output.save(fileName, bytes, 'application/octet-stream');

  /// Contenu du fichier choisi, ou `null` si annulé.
  Future<Uint8List?> pick() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return null;
    return files.first.xFile.readAsBytes();
  }
}

final backupEnvironmentProvider = Provider<BackupEnvironment>(
  (ref) => BackupEnvironment(ref.watch(fileOutputProvider)),
);

enum BackupActivity { idle, saving, restoring }

/// Échec affiché sous la ligne « Sauvegarde » (maquette).
enum BackupFailure { storageFull, other }

@immutable
class BackupState {
  const BackupState({
    this.activity = BackupActivity.idle,
    this.lastAt,
    this.lastSize,
    this.failure,
  });

  final BackupActivity activity;
  final DateTime? lastAt;

  /// Taille de la dernière sauvegarde, en octets.
  final int? lastSize;
  final BackupFailure? failure;

  bool get busy => activity != BackupActivity.idle;
}

/// Sauvegarde chiffrée par mot de passe vers l'emplacement choisi, et
/// restauration sans perte.
class BackupController extends Notifier<BackupState> {
  static const _lastAtKey = 'backup.lastAt';
  static const _lastSizeKey = 'backup.lastSize';

  final _prefs = SharedPreferencesAsync();

  BackupEnvironment get _env => ref.read(backupEnvironmentProvider);

  @override
  BackupState build() {
    unawaited(_loadLast());
    return const BackupState();
  }

  Future<void> _loadLast() async {
    try {
      final at = await _prefs.getInt(_lastAtKey);
      final size = await _prefs.getInt(_lastSizeKey);
      if (at == null) return;
      state = BackupState(
        activity: state.activity,
        lastAt: DateTime.fromMillisecondsSinceEpoch(at),
        lastSize: size,
        failure: state.failure,
      );
    } on Object catch (error, stack) {
      reportError(error, stack);
    }
  }

  /// Crée la sauvegarde puis demande où l'enregistrer. `false` si annulé ou
  /// en échec (voir [BackupState.failure]).
  Future<bool> backup(String password) async {
    if (state.busy) return false;
    final now = ref.read(clockProvider)();
    _set(BackupActivity.saving);
    try {
      final bytes = await BackupFile.create(
        db: ref.read(appDatabaseProvider),
        deviceKey: await ref.read(databaseKeyStoreProvider).readOrCreateKey(),
        password: password,
        workDir: await _env.workDir(),
        now: now,
      );
      final day =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      if (!await _env.save(
        'finao-$day.${BackupFile.extension}',
        bytes,
      )) {
        _set(BackupActivity.idle);
        return false;
      }
      await _prefs.setInt(_lastAtKey, now.millisecondsSinceEpoch);
      await _prefs.setInt(_lastSizeKey, bytes.length);
      state = BackupState(lastAt: now, lastSize: bytes.length);
      return true;
    } on Object catch (error, stack) {
      reportError(error, stack);
      _set(
        BackupActivity.idle,
        failure: _isStorageFull(error)
            ? BackupFailure.storageFull
            : BackupFailure.other,
      );
      return false;
    }
  }

  /// Fichier choisi par l'utilisateur, ou `null` si annulé.
  Future<Uint8List?> pickBackup() => _env.pick();

  /// Lit la sauvegarde ; lève [BackupException] (mot de passe, version).
  Future<BackupInfo> inspect(Uint8List bytes, String password) async =>
      BackupFile.inspect(
        bytes: bytes,
        password: password,
        workDir: await _env.workDir(),
        currentSchema: ref.read(appDatabaseProvider).schemaVersion,
      );

  /// Remplace toutes les données par la sauvegarde. En cas d'échec, les
  /// données actuelles sont remises en place et l'erreur est relancée.
  Future<void> restore(Uint8List bytes, String password) async {
    if (state.busy) return;
    _set(BackupActivity.restoring);
    try {
      final ready = await BackupFile.prepareRestore(
        bytes: bytes,
        password: password,
        deviceKey: await ref.read(databaseKeyStoreProvider).readOrCreateKey(),
        workDir: await _env.workDir(),
        currentSchema: ref.read(appDatabaseProvider).schemaVersion,
      );
      await replaceDatabaseFile(
        ready: ready,
        target: await _env.databaseFile(),
        close: () => ref.read(appDatabaseProvider).close(),
        reopen: () async {
          // Nouvelle instance : tous les écrans relisent les données, et les
          // migrations d'une sauvegarde plus ancienne s'appliquent ici.
          ref.invalidate(appDatabaseProvider);
          await ref
              .read(appDatabaseProvider)
              .customSelect('SELECT count(*) FROM accounts')
              .get();
        },
      );
    } finally {
      _set(BackupActivity.idle);
    }
  }

  void _set(BackupActivity activity, {BackupFailure? failure}) =>
      state = BackupState(
        activity: activity,
        lastAt: state.lastAt,
        lastSize: state.lastSize,
        failure: failure,
      );

  static bool _isStorageFull(Object error) => switch (error) {
    // ENOSPC
    FileSystemException(:final osError?) => osError.errorCode == 28,
    // SQLITE_FULL
    SqliteException(:final resultCode) => resultCode == 13,
    _ => false,
  };
}

final backupControllerProvider =
    NotifierProvider<BackupController, BackupState>(BackupController.new);
