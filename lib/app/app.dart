import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../features/assistant/presentation/ai_model_controller.dart';
import '../features/notifications/presentation/notification_scheduler.dart';
import '../features/security/presentation/lock_gate.dart';
import '../features/settings/presentation/settings_providers.dart';
import '../l10n/l10n.dart';
import 'finao_splash.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class FinanceApp extends ConsumerWidget {
  const FinanceApp({super.key, this.systemSplashShowsCairn = false});

  /// Android 12+ : le splash système a déjà affiché le cairn.
  final bool systemSplashShowsCairn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Démarre le suivi du modèle IA dès le lancement (compatibilité, et
    // chargement si « Charger l'IA au démarrage » est activé).
    ref
      ..listen(aiModelControllerProvider, (_, _) {})
      // Rappels et alertes reprogrammés à l'ouverture et à chaque changement.
      ..listen(notificationSchedulerProvider, (_, _) {});
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(appRouterProvider),
      // Splash animé au lancement, puis verrouillage par code PIN au-dessus
      // de tous les écrans.
      builder: (context, child) => FinaoSplash(
        stonesAlreadyShown: systemSplashShowsCairn,
        next: LockGate(child: child ?? const SizedBox()),
      ),
      // Application en français uniquement pour le MVP.
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      // Délégués Material/Cupertino/Widgets de material_ui (et non ceux de
      // flutter_localizations, liés à l'ancien package:flutter/material.dart).
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
    );
  }
}
