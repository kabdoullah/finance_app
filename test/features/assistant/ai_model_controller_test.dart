import 'package:finance_app/features/assistant/data/ai_platform.dart';
import 'package:finance_app/features/assistant/domain/ai_compatibility.dart';
import 'package:finance_app/features/assistant/presentation/ai_model_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_ai.dart';

void main() {
  group('compatibilité', () {
    test('téléphone milieu de gamme récent : compatible', () {
      expect(AiRequirements.check(fakeDevice()), isEmpty);
    });

    test('Android 10, 32 bits, 4 Go : trois raisons', () {
      expect(
        AiRequirements.check(
          fakeDevice(osVersion: 29, is64Bit: false, totalRam: 4 * gb),
        ),
        {
          AiIncompatibility.systemTooOld,
          AiIncompatibility.not64Bit,
          AiIncompatibility.notEnoughRam,
        },
      );
    });

    test('iPhone : iOS 15 minimum', () {
      expect(
        AiRequirements.check(fakeDevice(isIos: true, osVersion: 15)),
        isEmpty,
      );
      expect(AiRequirements.check(fakeDevice(isIos: true, osVersion: 14)), {
        AiIncompatibility.systemTooOld,
      });
    });

    test('6 Go annoncés (5,7 Go déclarés) : compatible', () {
      expect(AiRequirements.check(fakeDevice(totalRam: 5700000000)), isEmpty);
    });
  });

  group('cycle du modèle', () {
    late FakeDeviceInfo device;
    late FakeGemmaRuntime runtime;
    late FakeAiPreferences prefs;
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
      device = FakeDeviceInfo(fakeDevice());
      runtime = FakeGemmaRuntime();
      prefs = FakeAiPreferences();
    });

    test('hors Android : indisponible', () async {
      device.device = null;
      await start();
      expect(state().status, AiModelStatus.unavailable);
    });

    test('32 bits : indisponible, avec la raison', () async {
      device.device = fakeDevice(is64Bit: false);
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
      device.device = fakeDevice(availableRam: gb);
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
      device.device = fakeDevice(metered: true);
      expect(await controller().checkDownload(), DownloadCheck.metered);
      device.device = fakeDevice(freeStorage: 2 * gb);
      expect(
        await controller().checkDownload(),
        DownloadCheck.notEnoughStorage,
      );
    });
  });
}
