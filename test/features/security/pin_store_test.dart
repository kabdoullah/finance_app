import 'package:finance_app/features/security/data/pin_store.dart';
import 'package:finance_app/features/security/domain/pin_policy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PinPolicy', () {
    test('attente après chaque série de 5 essais, doublée', () {
      expect(PinPolicy.waitAfter(4), isNull);
      expect(PinPolicy.waitAfter(5), const Duration(seconds: 30));
      expect(PinPolicy.waitAfter(6), isNull);
      expect(PinPolicy.waitAfter(10), const Duration(minutes: 1));
      expect(PinPolicy.waitAfter(15), const Duration(minutes: 2));
      expect(PinPolicy.waitAfter(100), const Duration(hours: 1));
      expect(PinPolicy.remainingBeforeWait(3), 2);
    });

    test('code de 4 chiffres', () {
      expect(PinPolicy.isWellFormed('0427'), isTrue);
      expect(PinPolicy.isWellFormed('427'), isFalse);
      expect(PinPolicy.isWellFormed('12a4'), isFalse);
    });
  });

  group('PinStore', () {
    late FlutterSecureStorage storage;
    late PinStore store;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      storage = const FlutterSecureStorage();
      store = PinStore(storage, iterations: 10);
    });

    test('empreinte salée, jamais le code en clair', () async {
      await store.setPin('0427');
      final raw = (await storage.readAll()).values.join();
      expect(raw, isNot(contains('0427')));
      expect(await store.verify('0427'), isTrue);
      expect(await store.verify('0428'), isFalse);
      expect((await store.read()).enabled, isTrue);

      // Même code, autre sel : empreintes différentes.
      final first = await storage.read(key: 'lock.pin');
      await store.setPin('0427');
      expect(await storage.read(key: 'lock.pin'), isNot(first));
    });

    test('essais ratés conservés ; désactivation complète', () async {
      await store.setPin('1111');
      await store.setBiometric(true);
      await store.saveFailures(5, DateTime(2026, 11, 15, 10));
      var settings = await store.read();
      expect(settings.failures, 5);
      expect(settings.waitUntil, DateTime(2026, 11, 15, 10));
      expect(settings.delay, LockDelay.oneMinute);

      await store.clear();
      settings = await store.read();
      expect(settings.enabled, isFalse);
      expect(settings.biometric, isFalse);
      expect(settings.failures, 0);
      expect(await store.verify('1111'), isFalse);
    });
  });
}
