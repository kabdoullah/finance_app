import 'package:finance_app/core/database/database_key_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecureStorage storage;
  late DatabaseKeyStore keyStore;

  setUp(() {
    storage = _MockSecureStorage();
    keyStore = DatabaseKeyStore(storage);
  });

  test('réutilise la clé déjà enregistrée', () async {
    when(
      () => storage.read(key: DatabaseKeyStore.storageKey),
    ).thenAnswer((_) async => 'existing-key');

    expect(await keyStore.readOrCreateKey(), 'existing-key');
    verifyNever(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    );
  });

  test('crée et enregistre une clé au premier lancement', () async {
    when(
      () => storage.read(key: DatabaseKeyStore.storageKey),
    ).thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});

    final key = await keyStore.readOrCreateKey();

    verify(
      () => storage.write(key: DatabaseKeyStore.storageKey, value: key),
    ).called(1);
  });

  test('génère des clés de 256 bits, uniques et sûres pour PRAGMA key', () {
    final keys = {for (var i = 0; i < 50; i++) DatabaseKeyStore.generateKey()};

    expect(keys, hasLength(50));
    for (final key in keys) {
      // 32 octets en base64url sans remplissage = 43 caractères.
      expect(key, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    }
  });
}
