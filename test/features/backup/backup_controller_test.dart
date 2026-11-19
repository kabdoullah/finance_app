import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:finance_app/core/clock.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/database/database_connection.dart';
import 'package:finance_app/core/database/database_key_store.dart';
import 'package:finance_app/core/database/database_providers.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/backup/data/backup_file.dart';
import 'package:finance_app/features/backup/presentation/backup_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _deviceKey = 'cle-du-telephone-0123456789abcdefABCDEF';

class _FakeEnvironment extends BackupEnvironment {
  _FakeEnvironment(this.dir);

  final Directory dir;
  Uint8List? saved;
  String? savedName;

  File get db => File('${dir.path}/app_database.sqlite');

  @override
  Future<Directory> workDir() async => dir;

  @override
  Future<File> databaseFile() async => db;

  @override
  Future<bool> save(String fileName, Uint8List bytes) async {
    savedName = fileName;
    saved = bytes;
    return true;
  }

  @override
  Future<Uint8List?> pick() async => saved;
}

void main() {
  late Directory dir;
  late _FakeEnvironment env;
  late ProviderContainer container;
  final now = DateTime(2026, 11, 14, 21, 14);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('backup_controller');
    env = _FakeEnvironment(dir);
    FlutterSecureStorage.setMockInitialValues({
      DatabaseKeyStore.storageKey: _deviceKey,
    });
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        backupEnvironmentProvider.overrideWithValue(env),
        // Base chiffrée en fichier, rouverte après une restauration.
        appDatabaseProvider.overrideWith((ref) {
          final db = AppDatabase(
            NativeDatabase(
              env.db,
              setup: (raw) => applyEncryptionKey(raw, _deviceKey),
            ),
          );
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    dir.deleteSync(recursive: true);
  });

  Future<void> addAccount(String name) =>
      AccountsRepository(container.read(appDatabaseProvider), () => now).create(
        AccountDraft(
          type: AccountType.mobileMoney,
          name: name,
          openingBalance: const Money(1000),
        ),
      );

  Future<List<String>> accountNames() async {
    final db = container.read(appDatabaseProvider);
    return [for (final a in await db.select(db.accounts).get()) a.name];
  }

  BackupController controller() =>
      container.read(backupControllerProvider.notifier);

  test('sauvegarder, modifier, restaurer', () async {
    await addAccount('Wave');
    expect(await controller().backup('mot de passe 1'), isTrue);
    expect(env.savedName, 'finance-copilot-2026-11-14.fcbak');
    expect(container.read(backupControllerProvider).lastAt, now);
    expect(
      container.read(backupControllerProvider).lastSize,
      env.saved!.length,
    );

    await addAccount('Orange Money');
    expect(await accountNames(), hasLength(2));

    final bytes = (await controller().pickBackup())!;
    final info = await controller().inspect(bytes, 'mot de passe 1');
    expect(info.createdAt, now);
    await controller().restore(bytes, 'mot de passe 1');

    expect(await accountNames(), ['Wave']);
    // Ni copie de sécurité ni fichier de travail laissés.
    expect(dir.listSync().map((f) => f.uri.pathSegments.last), [
      'app_database.sqlite',
    ]);
    expect(container.read(backupControllerProvider).busy, isFalse);
  });

  test('mauvais mot de passe : données intactes', () async {
    await addAccount('Wave');
    await controller().backup('mot de passe 1');
    await addAccount('Orange Money');

    await expectLater(
      controller().restore(env.saved!, 'faux'),
      throwsA(isA<BackupException>()),
    );
    expect(await accountNames(), hasLength(2));
    expect(container.read(backupControllerProvider).busy, isFalse);
  });
}
