import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_reporter.dart';
import '../data/ai_platform.dart';
import '../domain/ai_compatibility.dart';

/// États de la maquette IA-Modele.
enum AiModelStatus {
  /// Vérification au lancement.
  checking,

  /// Téléphone non compatible (ou hors Android) : pas d'IA.
  unavailable,
  notInstalled,
  downloading,

  /// Installé, pas en mémoire.
  installed,
  loading,
  ready,

  /// Installé mais n'a pas pu démarrer.
  error,
}

/// Problème ponctuel à afficher (sans changer d'état).
enum AiModelNotice {
  downloadFailed,

  /// Moins de 2 Go de mémoire libre au moment de charger.
  lowMemory,
}

@immutable
class AiModelState {
  const AiModelState({
    this.status = AiModelStatus.checking,
    this.incompatibilities = const {},
    this.progress = 0,
    this.notice,
    this.loadOnStartup = false,
  });

  final AiModelStatus status;
  final Set<AiIncompatibility> incompatibilities;

  /// Pourcentage du téléchargement.
  final int progress;
  final AiModelNotice? notice;
  final bool loadOnStartup;

  bool get isInstalled => switch (status) {
    AiModelStatus.installed ||
    AiModelStatus.loading ||
    AiModelStatus.ready ||
    AiModelStatus.error => true,
    _ => false,
  };

  AiModelState copyWith({
    AiModelStatus? status,
    Set<AiIncompatibility>? incompatibilities,
    int? progress,
    AiModelNotice? Function()? notice,
    bool? loadOnStartup,
  }) => AiModelState(
    status: status ?? this.status,
    incompatibilities: incompatibilities ?? this.incompatibilities,
    progress: progress ?? this.progress,
    notice: notice == null ? this.notice : notice(),
    loadOnStartup: loadOnStartup ?? this.loadOnStartup,
  );
}

/// Vérification préalable au téléchargement.
enum DownloadCheck { ok, notEnoughStorage, metered }

/// Cycle de vie du modèle Gemma : compatibilité, téléchargement, chargement,
/// libération, suppression. Vit le temps de l'application.
class AiModelController extends Notifier<AiModelState> {
  InferenceModel? _model;
  CancelToken? _cancel;

  /// Modèle chargé, ou `null`.
  InferenceModel? get model => _model;

  DeviceInfoService get _device => ref.read(deviceInfoServiceProvider);
  GemmaRuntime get _runtime => ref.read(gemmaRuntimeProvider);

  @override
  AiModelState build() {
    ref.onDispose(() => unawaited(_model?.close()));
    unawaited(_start());
    return const AiModelState();
  }

  Future<void> _start() async {
    final device = await _device.read();
    if (device == null) {
      state = state.copyWith(status: AiModelStatus.unavailable);
      return;
    }
    final incompatibilities = AiRequirements.check(device);
    if (incompatibilities.isNotEmpty) {
      state = state.copyWith(
        status: AiModelStatus.unavailable,
        incompatibilities: incompatibilities,
      );
      return;
    }
    try {
      final prefs = ref.read(aiPreferencesProvider);
      final loadOnStartup = await prefs.loadOnStartup();
      final installed = await _runtime.isInstalled();
      state = state.copyWith(
        status: installed
            ? AiModelStatus.installed
            : AiModelStatus.notInstalled,
        loadOnStartup: loadOnStartup,
      );
      if (installed && loadOnStartup) await load();
    } on Object catch (error, stack) {
      reportError(error, stack);
      state = state.copyWith(status: AiModelStatus.unavailable);
    }
  }

  /// À appeler avant [download] : espace libre et type de connexion.
  Future<DownloadCheck> checkDownload() async {
    final device = await _device.read();
    if (device == null) return DownloadCheck.ok;
    if (!AiRequirements.hasRoomToDownload(device)) {
      return DownloadCheck.notEnoughStorage;
    }
    return device.metered ? DownloadCheck.metered : DownloadCheck.ok;
  }

  Future<void> download() async {
    if (state.status != AiModelStatus.notInstalled) return;
    await _device.requestNotifications();
    final cancel = _cancel = CancelToken();
    state = state.copyWith(
      status: AiModelStatus.downloading,
      progress: 0,
      notice: () => null,
    );
    try {
      await _runtime.install(
        cancel: cancel,
        onProgress: (percent) {
          if (state.status == AiModelStatus.downloading) {
            state = state.copyWith(progress: percent);
          }
        },
      );
      state = state.copyWith(status: AiModelStatus.installed, progress: 100);
    } on DownloadCancelledException {
      state = state.copyWith(status: AiModelStatus.notInstalled, progress: 0);
    } on Object catch (error, stack) {
      reportError(error, stack);
      state = state.copyWith(
        status: AiModelStatus.notInstalled,
        progress: 0,
        notice: () => AiModelNotice.downloadFailed,
      );
    } finally {
      _cancel = null;
    }
  }

  void cancelDownload() => _cancel?.cancel();

  /// Charge le modèle en mémoire (quelques secondes). Refuse s'il reste
  /// moins de 2 Go de mémoire libre.
  Future<void> load() async {
    if (state.status != AiModelStatus.installed &&
        state.status != AiModelStatus.error) {
      return;
    }
    final device = await _device.read();
    if (device != null && !AiRequirements.hasMemoryToLoad(device)) {
      state = state.copyWith(notice: () => AiModelNotice.lowMemory);
      return;
    }
    state = state.copyWith(status: AiModelStatus.loading, notice: () => null);
    try {
      _model = await _runtime.load();
      state = state.copyWith(status: AiModelStatus.ready);
    } on Object catch (error, stack) {
      reportError(error, stack);
      state = state.copyWith(status: AiModelStatus.error);
    }
  }

  /// « Continuer sans IA » : on revient à l'état installé.
  void dismissError() {
    if (state.status == AiModelStatus.error) {
      state = state.copyWith(status: AiModelStatus.installed);
    }
  }

  Future<void> unload() async {
    final model = _model;
    _model = null;
    await model?.close();
    if (state.status == AiModelStatus.ready) {
      state = state.copyWith(status: AiModelStatus.installed);
    }
  }

  Future<void> delete() async {
    await unload();
    await _runtime.uninstall();
    state = state.copyWith(
      status: AiModelStatus.notInstalled,
      progress: 0,
      notice: () => null,
    );
  }

  Future<void> setLoadOnStartup(bool value) async {
    state = state.copyWith(loadOnStartup: value);
    await ref.read(aiPreferencesProvider).setLoadOnStartup(value);
  }
}

final aiModelControllerProvider =
    NotifierProvider<AiModelController, AiModelState>(AiModelController.new);
