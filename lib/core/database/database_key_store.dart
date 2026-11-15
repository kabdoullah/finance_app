import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gère la clé de chiffrement de la base, conservée dans le Keychain (iOS)
/// ou le Keystore (Android), jamais dans un fichier ou dans le code.
class DatabaseKeyStore {
  DatabaseKeyStore(this._storage);

  static const storageKey = 'database_encryption_key';

  final FlutterSecureStorage _storage;

  /// Retourne la clé existante, ou en crée une au premier lancement.
  Future<String> readOrCreateKey() async {
    final existing = await _storage.read(key: storageKey);
    if (existing != null) return existing;

    final key = generateKey();
    await _storage.write(key: storageKey, value: key);
    return key;
  }

  /// 32 octets aléatoires (CSPRNG) encodés en base64url sans remplissage :
  /// uniquement `[A-Za-z0-9_-]`, donc sûrs dans un `PRAGMA key`.
  @visibleForTesting
  static String generateKey([Random? random]) {
    final rng = random ?? Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
