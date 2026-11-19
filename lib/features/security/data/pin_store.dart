import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/pin_policy.dart';

/// Réglages du verrouillage lus au lancement.
class LockSettings {
  const LockSettings({
    required this.enabled,
    required this.biometric,
    required this.delay,
    required this.failures,
    required this.waitUntil,
  });

  final bool enabled;
  final bool biometric;
  final LockDelay delay;

  /// Codes faux consécutifs, et fin de l'attente imposée.
  final int failures;
  final DateTime? waitUntil;
}

/// Code PIN et réglages du verrouillage, dans le coffre sécurisé d'Android
/// (Keystore), comme la clé de la base. Le code n'est jamais stocké : seule
/// une empreinte PBKDF2-HMAC-SHA256 salée l'est. Il bloque l'accès à
/// l'application ; la base, elle, est chiffrée par sa propre clé.
class PinStore {
  PinStore(this._storage, {this.iterations = 100000});

  final FlutterSecureStorage _storage;

  /// Coût du calcul (réduit dans les tests).
  final int iterations;

  static const _pinKey = 'lock.pin';
  static const _biometricKey = 'lock.biometric';
  static const _delayKey = 'lock.delay';
  static const _failuresKey = 'lock.failures';
  static const _waitKey = 'lock.waitUntil';

  Future<LockSettings> read() async {
    final values = await _storage.readAll();
    final wait = int.tryParse(values[_waitKey] ?? '');
    return LockSettings(
      enabled: values[_pinKey] != null,
      biometric: values[_biometricKey] == 'true',
      delay: LockDelay.values.firstWhere(
        (d) => d.name == values[_delayKey],
        orElse: () => LockDelay.oneMinute,
      ),
      failures: int.tryParse(values[_failuresKey] ?? '') ?? 0,
      waitUntil: wait == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(wait),
    );
  }

  Future<void> setPin(String pin) async {
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final hash = await _derive(pin, salt, iterations);
    await _storage.write(
      key: _pinKey,
      value: jsonEncode({
        'v': 1,
        'it': iterations,
        'salt': base64Encode(salt),
        'hash': base64Encode(hash),
      }),
    );
    await resetFailures();
  }

  /// Vrai si [pin] est le bon code (comparaison à temps constant).
  Future<bool> verify(String pin) async {
    final raw = await _storage.read(key: _pinKey);
    if (raw == null) return false;
    final record = (jsonDecode(raw) as Map).cast<String, Object?>();
    final expected = base64Decode(record['hash']! as String);
    final actual = await _derive(
      pin,
      base64Decode(record['salt']! as String),
      record['it']! as int,
    );
    if (actual.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual[i] ^ expected[i];
    }
    return diff == 0;
  }

  /// Désactive le verrouillage (code et biométrie oubliés).
  Future<void> clear() async {
    for (final key in [_pinKey, _biometricKey, _failuresKey, _waitKey]) {
      await _storage.delete(key: key);
    }
  }

  Future<void> setBiometric(bool value) =>
      _storage.write(key: _biometricKey, value: '$value');

  Future<void> setDelay(LockDelay delay) =>
      _storage.write(key: _delayKey, value: delay.name);

  Future<void> saveFailures(int failures, DateTime? waitUntil) async {
    await _storage.write(key: _failuresKey, value: '$failures');
    if (waitUntil == null) {
      await _storage.delete(key: _waitKey);
    } else {
      await _storage.write(
        key: _waitKey,
        value: '${waitUntil.millisecondsSinceEpoch}',
      );
    }
  }

  Future<void> resetFailures() => saveFailures(0, null);

  /// PBKDF2 hors du fil de l'interface quand il est coûteux.
  static Future<List<int>> _derive(String pin, List<int> salt, int iterations) {
    Future<List<int>> run() async {
      final key = await Pbkdf2.hmacSha256(
        iterations: iterations,
        bits: 256,
      ).deriveKeyFromPassword(password: pin, nonce: salt);
      return key.extractBytes();
    }

    return iterations >= 1000 ? Isolate.run(run) : run();
  }
}

final pinStoreProvider = Provider<PinStore>(
  (ref) => PinStore(const FlutterSecureStorage()),
);
