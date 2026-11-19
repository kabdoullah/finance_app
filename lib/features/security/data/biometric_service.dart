import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/errors/error_reporter.dart';

/// Empreinte ou visage (local_auth). Hors Android ou sans capteur : jamais
/// disponible, le code PIN suffit.
class BiometricService {
  BiometricService();

  final _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on MissingPluginException {
      return false;
    } on Object catch (error, stack) {
      reportError(error, stack);
      return false;
    }
  }

  /// Vrai si l'utilisateur a été reconnu.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } on MissingPluginException {
      return false;
    } on Object catch (error, stack) {
      reportError(error, stack);
      return false;
    }
  }
}

final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(),
);

/// Masque le contenu dans les applications récentes (et bloque les captures)
/// quand le verrouillage est actif.
class SecureWindow {
  const SecureWindow();

  static const _channel = MethodChannel('finance_app/device');

  Future<void> set(bool secure) async {
    try {
      await _channel.invokeMethod<void>('setSecure', secure);
    } on MissingPluginException {
      // Hors Android.
    }
  }
}

final secureWindowProvider = Provider<SecureWindow>(
  (ref) => const SecureWindow(),
);
