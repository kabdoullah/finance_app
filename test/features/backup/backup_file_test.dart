import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/database/database_connection.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/backup/data/backup_file.dart';
import 'package:flutter_test/flutter_test.dart';

const _deviceKey = 'cle-du-telephone-0123456789abcdefABCDEF';

AppDatabase _open(File file, String key) => AppDatabase(
  NativeDatabase(file, setup: (db) => applyEncryptionKey(db, key)),
);

void main() {
  late Directory dir;
  late AppDatabase db;
  final now = DateTime(2026, 11, 14, 21, 14);

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('backup_test');
    db = _open(File('${dir.path}/app.sqlite'), _deviceKey);
    await AccountsRepository(db, () => now).create(
      const AccountDraft(
        type: AccountType.mobileMoney,
        name: 'Wave',
        openingBalance: Money(42000),
      ),
    );
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<Uint8List> backup(String password) => BackupFile.create(
    db: db,
    deviceKey: _deviceKey,
    password: password,
    workDir: dir,
    now: now,
  );

  test(
    'chiffrée par le mot de passe, rien en clair, pas de fichier laissé',
    () async {
      final bytes = await backup('mon mot de passe');
      expect(String.fromCharCodes(bytes), isNot(contains('Wave')));
      expect(dir.listSync().map((f) => f.uri.pathSegments.last), [
        'app.sqlite',
      ]);

      final info = await BackupFile.inspect(
        bytes: bytes,
        password: 'mon mot de passe',
        workDir: dir,
        currentSchema: db.schemaVersion,
      );
      expect(info.createdAt, now);
      expect(info.schemaVersion, db.schemaVersion);
    },
  );

  test(
    'mauvais mot de passe, fichier quelconque, version plus récente',
    () async {
      final bytes = await backup('mon mot de passe');
      Future<BackupInfo> inspect(Uint8List b, String pw, int schema) =>
          BackupFile.inspect(
            bytes: b,
            password: pw,
            workDir: dir,
            currentSchema: schema,
          );
      await expectLater(
        inspect(bytes, 'faux', db.schemaVersion),
        throwsA(
          isA<BackupException>().having(
            (e) => e.error,
            'error',
            BackupError.unreadable,
          ),
        ),
      );
      await expectLater(
        inspect(
          Uint8List.fromList('pas une sauvegarde'.codeUnits),
          'x',
          db.schemaVersion,
        ),
        throwsA(isA<BackupException>()),
      );
      await expectLater(
        inspect(bytes, 'mon mot de passe', db.schemaVersion - 1),
        throwsA(
          isA<BackupException>().having(
            (e) => e.error,
            'error',
            BackupError.tooNew,
          ),
        ),
      );
      expect(dir.listSync(), hasLength(1));
    },
  );

  test('restauration : fichier rechiffré avec la clé du téléphone', () async {
    final bytes = await backup('mon mot de passe');
    final ready = await BackupFile.prepareRestore(
      bytes: bytes,
      password: 'mon mot de passe',
      deviceKey: _deviceKey,
      workDir: dir,
      currentSchema: db.schemaVersion,
    );
    final restored = _open(ready, _deviceKey);
    try {
      final accounts = await restored.select(restored.accounts).get();
      expect(accounts.single.name, 'Wave');
      final tables = await restored
          .customSelect(
            "SELECT name FROM sqlite_master WHERE name = 'backup_info'",
          )
          .get();
      expect(tables, isEmpty);
    } finally {
      await restored.close();
    }
  });
}
