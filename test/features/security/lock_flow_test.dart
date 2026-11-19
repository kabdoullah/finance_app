import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/features/security/data/biometric_service.dart';
import 'package:finance_app/features/security/data/pin_store.dart';
import 'package:finance_app/features/security/presentation/lock_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_app.dart';

class _FakeBiometrics extends BiometricService {
  _FakeBiometrics({required this.recognized});

  bool recognized;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return recognized;
  }
}

void main() {
  late AppDatabase db;
  late _FakeBiometrics biometrics;

  setUp(() {
    db = newTestDatabase();
    FlutterSecureStorage.setMockInitialValues({});
    biometrics = _FakeBiometrics(recognized: false);
  });
  tearDown(() => db.close());

  Future<void> start(WidgetTester tester) => pumpTestApp(
    tester,
    db,
    overrides: [
      pinStoreProvider.overrideWithValue(
        PinStore(const FlutterSecureStorage(), iterations: 10),
      ),
      biometricServiceProvider.overrideWithValue(biometrics),
    ],
  );

  LockController controller(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
          .read(lockControllerProvider.notifier);

  /// Tape [pin] sur le pavé. [settle] : attendre la fin des animations
  /// (impossible pendant une attente imposée, dont le compte à rebours bat
  /// chaque seconde).
  Future<void> type(
    WidgetTester tester,
    String pin, {
    bool settle = true,
  }) async {
    for (final digit in pin.split('')) {
      await tester.tap(find.text(digit).last);
      await tester.pump();
    }
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Passage en arrière-plan puis retour, délai écoulé (« Immédiatement »).
  Future<void> leaveAndComeBack(WidgetTester tester) async {
    controller(tester)
      ..onHidden()
      ..onResumed();
    await tester.pumpAndSettle();
  }

  testWidgets('activer, verrouiller, se tromper, déverrouiller, désactiver', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tapSetting(tester, 'Verrouillage de l\'application');
    await tester.pumpAndSettle();
    expect(find.text('Choisis un code'), findsOneWidget);
    expect(find.textContaining('un code oublié ne peut pas'), findsOneWidget);

    // Confirmation différente : on recommence.
    await type(tester, '1234');
    await type(tester, '9999');
    expect(
      find.text('Les deux codes ne correspondent pas. Recommence.'),
      findsOneWidget,
    );
    await type(tester, '1234');
    await type(tester, '1234');
    expect(find.text('Verrouillage activé.'), findsOneWidget);
    expect(find.text('Verrouiller après'), findsOneWidget);
    expect(find.text('1 minute'), findsOneWidget);

    await tapSetting(tester, 'Verrouiller après');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Immédiatement'));
    await tester.pumpAndSettle();

    await leaveAndComeBack(tester);
    expect(find.text('Saisis ton code'), findsOneWidget);
    await type(tester, '0000');
    expect(find.text('Code incorrect. Encore 4 essais.'), findsOneWidget);
    await type(tester, '1234');
    expect(find.text('Saisis ton code'), findsNothing);

    // Désactivation : code actuel demandé.
    await tapSetting(tester, 'Verrouillage de l\'application');
    await tester.pumpAndSettle();
    expect(find.text('Code actuel'), findsOneWidget);
    await type(tester, '1234');
    expect(find.text('Verrouillage désactivé.'), findsOneWidget);
    await leaveAndComeBack(tester);
    expect(find.text('Saisis ton code'), findsNothing);
  });

  testWidgets('5 codes faux : attente imposée ; empreinte au lancement', (
    tester,
  ) async {
    final store = PinStore(const FlutterSecureStorage(), iterations: 10);
    await store.setPin('1234');
    await store.setBiometric(true);
    await start(tester);

    // Verrouillé au lancement ; empreinte proposée mais refusée.
    expect(find.text('Saisis ton code'), findsOneWidget);
    expect(biometrics.prompts, 1);

    for (var i = 0; i < 4; i++) {
      await type(tester, '0000');
    }
    await type(tester, '0000', settle: false);
    expect(
      find.textContaining('Trop d\'essais. Réessaie dans'),
      findsOneWidget,
    );
    // Même le bon code est refusé pendant l'attente.
    await type(tester, '1234', settle: false);
    expect(find.text('Saisis ton code'), findsOneWidget);

    // L'empreinte reconnue déverrouille et remet les essais à zéro.
    biometrics.recognized = true;
    await controller(tester).unlockWithBiometrics('test');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Saisis ton code'), findsNothing);
    expect((await store.read()).failures, 0);
  });
}
