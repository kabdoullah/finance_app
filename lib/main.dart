import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/errors/error_reporter.dart';
import 'features/settings/data/app_preferences.dart';
import 'features/settings/presentation/settings_providers.dart';

Future<void> main() async {
  installGlobalErrorHandlers();
  WidgetsFlutterBinding.ensureInitialized();
  // Réglage lu avant le premier écran : les totaux du mois sont calculés
  // d'emblée sur le bon mois budgétaire.
  var monthStart = 1;
  try {
    monthStart = await AppPreferences(SharedPreferencesAsync())
        .budgetMonthStart();
  } on Object catch (error, stack) {
    reportError(error, stack);
  }
  runApp(
    ProviderScope(
      overrides: [
        budgetMonthStartProvider.overrideWith(
          () => BudgetMonthStart(monthStart),
        ),
      ],
      child: const FinanceApp(),
    ),
  );
}
