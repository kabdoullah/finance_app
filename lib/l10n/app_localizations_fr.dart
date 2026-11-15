// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Finance Copilot';

  @override
  String get navHome => 'Accueil';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navBudgets => 'Budgets';

  @override
  String get navForecast => 'Prévisions';

  @override
  String get navAssistant => 'Assistant';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get comingSoonMessage => 'Cet écran arrive bientôt.';

  @override
  String get dashboardWelcome => 'Bienvenue';

  @override
  String get dashboardTotalBalance => 'Solde total';

  @override
  String get dashboardEmptyBalanceHint =>
      'Ajoute un compte pour voir ton solde réel.';

  @override
  String get dashboardGetStartedTitle => 'Pour bien démarrer';

  @override
  String get dashboardStepAccountsTitle => 'Ajoute tes comptes';

  @override
  String get dashboardStepAccountsSubtitle =>
      'Espèces, Wave, Orange Money, banque…';

  @override
  String get dashboardStepTransactionsTitle =>
      'Saisis tes premières opérations';

  @override
  String get dashboardStepTransactionsSubtitle =>
      'Une dépense, un revenu, un transfert';

  @override
  String get dashboardStepBudgetTitle => 'Fixe un premier budget';

  @override
  String get dashboardStepBudgetSubtitle => 'Par exemple pour l\'alimentation';

  @override
  String get dashboardCopilotHint =>
      'Tu peux aussi l\'écrire simplement : « J\'ai 25 000 FCFA sur Wave ».';

  @override
  String get dashboardCopilotAction => 'Écrire au Copilote';

  @override
  String get dashboardPrivacyNote =>
      'Tes données restent sur ce téléphone. Les prévisions apparaîtront après environ deux semaines d\'opérations.';

  @override
  String get currencyLabel => 'FCFA';
}
