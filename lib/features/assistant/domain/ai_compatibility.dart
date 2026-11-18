import 'package:flutter/foundation.dart' show immutable;

/// Caractéristiques du téléphone utiles à l'IA (lues côté Android).
@immutable
class DeviceCapabilities {
  const DeviceCapabilities({
    required this.sdk,
    required this.is64Bit,
    required this.totalRamBytes,
    required this.availableRamBytes,
    required this.freeStorageBytes,
    required this.metered,
  });

  /// Version d'Android (API).
  final int sdk;
  final bool is64Bit;
  final int totalRamBytes;
  final int availableRamBytes;
  final int freeStorageBytes;

  /// Connexion facturée au volume (données mobiles) plutôt que Wi-Fi.
  final bool metered;
}

/// Pourquoi l'IA n'est pas proposée sur ce téléphone.
enum AiIncompatibility { androidTooOld, not64Bit, notEnoughRam }

/// Règles de compatibilité de Gemma 4 E2B (mesures du POC : 1,9 Go de
/// mémoire au pic, 2,47 Go de fichier).
abstract final class AiRequirements {
  static const _gb = 1000 * 1000 * 1000;

  /// LiteRT-LM demande Android 11.
  static const minSdk = 30;

  /// 6 Go annoncés : Android en déclare un peu moins (≈ 5,5 Go).
  static const minTotalRamBytes = 5 * _gb + _gb ~/ 2;

  /// Mémoire libre nécessaire pour charger le modèle.
  static const minAvailableRamBytes = 2 * _gb;

  /// Taille du fichier du modèle.
  static const modelBytes = 2470 * 1000 * 1000;

  /// Espace libre exigé avant le téléchargement (fichier + marge).
  static const minFreeStorageBytes = 3 * _gb;

  static Set<AiIncompatibility> check(DeviceCapabilities device) => {
    if (device.sdk < minSdk) AiIncompatibility.androidTooOld,
    if (!device.is64Bit) AiIncompatibility.not64Bit,
    if (device.totalRamBytes < minTotalRamBytes) AiIncompatibility.notEnoughRam,
  };

  static bool hasRoomToDownload(DeviceCapabilities device) =>
      device.freeStorageBytes >= minFreeStorageBytes;

  static bool hasMemoryToLoad(DeviceCapabilities device) =>
      device.availableRamBytes >= minAvailableRamBytes;
}
