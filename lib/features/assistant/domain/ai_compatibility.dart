import 'package:flutter/foundation.dart' show immutable;

/// Caractéristiques du téléphone utiles à l'IA (lues côté Android).
@immutable
class DeviceCapabilities {
  const DeviceCapabilities({
    required this.isIos,
    required this.osVersion,
    required this.is64Bit,
    required this.totalRamBytes,
    required this.availableRamBytes,
    required this.freeStorageBytes,
    required this.metered,
  });

  final bool isIos;

  /// Version du système : niveau d'API Android, ou version majeure d'iOS.
  final int osVersion;
  final bool is64Bit;
  final int totalRamBytes;
  final int availableRamBytes;
  final int freeStorageBytes;

  /// Connexion facturée au volume (données mobiles) plutôt que Wi-Fi.
  final bool metered;
}

/// Pourquoi l'IA n'est pas proposée sur ce téléphone.
enum AiIncompatibility { systemTooOld, not64Bit, notEnoughRam }

/// Règles de compatibilité de Gemma 4 E2B (mesures du POC : 1,9 Go de
/// mémoire au pic, 2,47 Go de fichier).
abstract final class AiRequirements {
  static const _gb = 1000 * 1000 * 1000;

  /// LiteRT-LM demande Android 11 (API 30) ou iOS 15.
  static const minAndroidSdk = 30;
  static const minIosVersion = 15;

  /// 6 Go annoncés : Android en déclare un peu moins (≈ 5,5 Go).
  static const minTotalRamBytes = 5 * _gb + _gb ~/ 2;

  /// Mémoire libre nécessaire pour charger le modèle.
  static const minAvailableRamBytes = 2 * _gb;

  /// Taille du fichier du modèle.
  static const modelBytes = 2470 * 1000 * 1000;

  /// Espace libre exigé avant le téléchargement (fichier + marge).
  static const minFreeStorageBytes = 3 * _gb;

  static Set<AiIncompatibility> check(DeviceCapabilities device) => {
    if (device.osVersion < (device.isIos ? minIosVersion : minAndroidSdk))
      AiIncompatibility.systemTooOld,
    if (!device.is64Bit) AiIncompatibility.not64Bit,
    if (device.totalRamBytes < minTotalRamBytes) AiIncompatibility.notEnoughRam,
  };

  static bool hasRoomToDownload(DeviceCapabilities device) =>
      device.freeStorageBytes >= minFreeStorageBytes;

  static bool hasMemoryToLoad(DeviceCapabilities device) =>
      device.availableRamBytes >= minAvailableRamBytes;
}
