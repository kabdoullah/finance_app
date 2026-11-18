import 'dart:async';

import 'package:finance_app/features/assistant/data/ai_platform.dart';
import 'package:finance_app/features/assistant/domain/ai_compatibility.dart';
import 'package:finance_app/features/assistant/presentation/ai_model_controller.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _gb = 1000 * 1000 * 1000;

DeviceCapabilities _device({
  int sdk = 34,
  bool is64Bit = true,
  int totalRam = 8 * _gb,
  int availableRam = 4 * _gb,
  int freeStorage = 20 * _gb,
  bool metered = false,
}) => DeviceCapabilities(
  sdk: sdk,
  is64Bit: is64Bit,
  totalRamBytes: totalRam,
  availableRamBytes: availableRam,
  freeStorageBytes: freeStorage,
  metered: metered,
);

class _FakeDevice extends DeviceInfoService {
  _FakeDevice(this.device);

  DeviceCapabilities? device;

  @override
  Future<DeviceCapabilities?> read() async => device;

  @override
  Future<void> requestNotifications() async {}
}

class _FakeModel implements InferenceModel {
  bool closed = false;

  @override
  Future<void> close() async => closed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRuntime extends GemmaRuntime {
  bool installed = false;
  bool failLoad = false;
  Completer<void>? pendingInstall;
  final model = _FakeModel();

  @override
  Future<bool> isInstalled() async => installed;

  @override
  Future<void> install({
    required void Function(int percent) onProgress,
    required CancelToken cancel,
  }) async {
    onProgress(40);
    final pending = pendingInstall = Completer<void>();
    unawaited(
      cancel.whenCancelled.then((_) {
        if (!pending.isCompleted) {
          pending.completeError(
            DownloadCancelledException('annulé', StackTrace.current),
          );
        }
      }),
    );
    await pending.future;
    installed = true;
  }

  @override
  Future<InferenceModel> load() async {
    if (failLoad) throw StateError('échec');
    return model;
  }

  @override
  Future<void> uninstall() async => installed = false;
}

class _FakePrefs implements AiPreferences {
  bool value = false;

  @override
  Future<bool> loadOnStartup() async => value;

  @override
  Future<void> setLoadOnStartup(bool value) async => this.value = value;
}

void main() {
  group('compatibilité', () {
    test('téléphone milieu de gamme récent : compatible', () {
      expect(AiRequirements.check(_device()), isEmpty);
    });

    test('Android 10, 32 bits, 4 Go : trois raisons', () {
      expect(
        AiRequirements.check(
          _device(sdk: 29, is64Bit: false, totalRam: 4 * _gb),
        ),
        {
          AiIncompatibility.androidTooOld,
          AiIncompatibility.not64Bit,
          AiIncompatibility.notEnoughRam,
        },
      );
    });

    test('6 Go annoncés (5,7 Go déclarés) : compatible', () {
      expect(AiRequirements.check(_device(totalRam: 5700000000)), isEmpty);
    });
  });

  group('cycle du modèle', () {
    late _FakeDevice device;
    late _FakeRuntime runtime;
    late _FakePrefs prefs;
    late ProviderContainer container;

    AiModelState state() => container.read(aiModelControllerProvider);
    AiModelController controller() =>
        container.read(aiModelControllerProvider.notifier);

    Future<void> start() async {
      container = ProviderContainer(
        overrides: [
          deviceInfoServiceProvider.overrideWithValue(device),
          gemmaRuntimeProvider.overrideWithValue(runtime),
          aiPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      container.read(aiModelControllerProvider);
      await pumpEventQueue();
    }

    setUp(() {
      device = _FakeDevice(_device());
      runtime = _FakeRuntime();
      prefs = _FakePrefs();
    });

    test('hors Android : indisponible', () async {
      device.device = null;
      await start();
      expect(state().status, AiModelStatus.unavailable);
    });

    test('32 bits : indisponible, avec la raison', () async {
      device.device = _device(is64Bit: false);
      await start();
      expect(state().status, AiModelStatus.unavailable);
      expect(state().incompatibilities, {AiIncompatibility.not64Bit});
    });

    test('installer, charger, libérer, supprimer', () async {
      await start();
      expect(state().status, AiModelStatus.notInstalled);

      final download = controller().download();
      await pumpEventQueue();
      expect(state().status, AiModelStatus.downloading);
      expect(state().progress, 40);
      runtime.pendingInstall!.complete();
      await download;
      expect(state().status, AiModelStatus.installed);

      await controller().load();
      expect(state().status, AiModelStatus.ready);
      expect(controller().model, same(runtime.model));

      await controller().unload();
      expect(state().status, AiModelStatus.installed);
      expect(runtime.model.closed, isTrue);

      await controller().delete();
      expect(state().status, AiModelStatus.notInstalled);
      expect(runtime.installed, isFalse);
    });

    test('annuler le téléchargement', () async {
      await start();
      final download = controller().download();
      await pumpEventQueue();
      controller().cancelDownload();
      await download;
      expect(state().status, AiModelStatus.notInstalled);
      expect(state().notice, isNull);
    });

    test('mémoire libre insuffisante : refus de charger', () async {
      runtime.installed = true;
      device.device = _device(availableRam: _gb);
      await start();
      await controller().load();
      expect(state().status, AiModelStatus.installed);
      expect(state().notice, AiModelNotice.lowMemory);
    });

    test('échec de démarrage, puis « Continuer sans IA »', () async {
      runtime
        ..installed = true
        ..failLoad = true;
      await start();
      await controller().load();
      expect(state().status, AiModelStatus.error);
      controller().dismissError();
      expect(state().status, AiModelStatus.installed);
    });

    test('« Charger l\'IA au démarrage » : chargé dès le lancement', () async {
      runtime.installed = true;
      prefs.value = true;
      await start();
      expect(state().status, AiModelStatus.ready);
    });

    test('vérifications avant téléchargement', () async {
      await start();
      expect(await controller().checkDownload(), DownloadCheck.ok);
      device.device = _device(metered: true);
      expect(await controller().checkDownload(), DownloadCheck.metered);
      device.device = _device(freeStorage: 2 * _gb);
      expect(
        await controller().checkDownload(),
        DownloadCheck.notEnoughStorage,
      );
    });
  });
}
