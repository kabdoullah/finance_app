import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class FinanceApp extends ConsumerWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: ref.watch(appRouterProvider),
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
