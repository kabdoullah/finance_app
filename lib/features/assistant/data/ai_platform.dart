import 'package:flutter/services.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ai_compatibility.dart';

/// Caractéristiques du téléphone (canal `finance_app/device`, MainActivity).
class DeviceInfoService {
  const DeviceInfoService();

  static const _channel = MethodChannel('finance_app/device');

  /// `null` hors Android (tests, ordinateur) : l'IA y est indisponible.
  Future<DeviceCapabilities?> read() async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('info');
      if (raw == null) return null;
      return DeviceCapabilities(
        sdk: raw['sdk']! as int,
        is64Bit: raw['is64Bit']! as bool,
        totalRamBytes: raw['totalRam']! as int,
        availableRamBytes: raw['availableRam']! as int,
        freeStorageBytes: raw['freeStorage']! as int,
        metered: raw['metered']! as bool,
      );
    } on MissingPluginException {
      return null;
    }
  }

  /// Autorisation d'afficher la notification du téléchargement (un refus
  /// n'empêche pas le téléchargement).
  Future<void> requestNotifications() async {
    try {
      await _channel.invokeMethod<bool>('requestNotifications');
    } on MissingPluginException {
      // Hors Android.
    }
  }
}

/// Gemma 4 E2B sur le téléphone, via flutter_edge_ai (LiteRT-LM, CPU).
/// Seule porte d'entrée vers le paquet : à n'utiliser que sur un téléphone
/// compatible ([AiRequirements.check]).
class GemmaRuntime {
  GemmaRuntime();

  static const modelFile = 'gemma-4-E2B-it.litertlm';

  /// Révision épinglée : le fichier ne change pas sans qu'on le décide.
  static const modelUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/'
      'resolve/b3ca0d2f076785a8f4b2219ddbd2bdb99954eae1/$modelFile';

  Future<void>? _initialized;

  Future<void> _init() => _initialized ??= FlutterEdgeAi.initialize(
    inferenceEngines: const [LiteRtLmEngine()],
  );

  Future<bool> isInstalled() async {
    await _init();
    return FlutterEdgeAi.isModelInstalled(modelFile);
  }

  /// Télécharge le modèle (service au premier plan). [onProgress] reçoit un
  /// pourcentage. Lève [DownloadCancelledException] si [cancel] est déclenché.
  Future<void> install({
    required void Function(int percent) onProgress,
    required CancelToken cancel,
  }) async {
    await _init();
    await FlutterEdgeAi.installModel(
          modelType: ModelType.gemma4,
          fileType: ModelFileType.litertlm,
        )
        .fromNetwork(modelUrl, foreground: true)
        .withProgress(onProgress)
        .withCancelToken(cancel)
        .install();
  }

  /// Charge le modèle en mémoire, sur le CPU (le GPU Mali n'apporte rien et
  /// se charge en ~40 s, voir tools/ai_poc/RAPPORT.md).
  Future<InferenceModel> load() async {
    await _init();
    return FlutterEdgeAi.getActiveModel(
      maxTokens: 2048,
      preferredBackend: PreferredBackend.cpu,
    );
  }

  Future<void> uninstall() async {
    await _init();
    await FlutterEdgeAi.uninstallModel(modelFile);
  }
}

/// Préférences de l'IA (pas des données financières : hors base chiffrée).
class AiPreferences {
  const AiPreferences(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _loadOnStartup = 'ai.loadOnStartup';

  Future<bool> loadOnStartup() async =>
      await _prefs.getBool(_loadOnStartup) ?? false;

  Future<void> setLoadOnStartup(bool value) =>
      _prefs.setBool(_loadOnStartup, value);
}

final deviceInfoServiceProvider = Provider<DeviceInfoService>(
  (ref) => const DeviceInfoService(),
);

final gemmaRuntimeProvider = Provider<GemmaRuntime>((ref) => GemmaRuntime());

final aiPreferencesProvider = Provider<AiPreferences>(
  (ref) => AiPreferences(SharedPreferencesAsync()),
);
