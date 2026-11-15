import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Finance Copilot'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navBudgets.
  ///
  /// In fr, this message translates to:
  /// **'Budgets'**
  String get navBudgets;

  /// No description provided for @navForecast.
  ///
  /// In fr, this message translates to:
  /// **'Prévisions'**
  String get navForecast;

  /// No description provided for @navAssistant.
  ///
  /// In fr, this message translates to:
  /// **'Assistant'**
  String get navAssistant;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @comingSoonMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cet écran arrive bientôt.'**
  String get comingSoonMessage;

  /// No description provided for @dashboardWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get dashboardWelcome;

  /// No description provided for @dashboardTotalBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde total'**
  String get dashboardTotalBalance;

  /// No description provided for @dashboardEmptyBalanceHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute un compte pour voir ton solde réel.'**
  String get dashboardEmptyBalanceHint;

  /// No description provided for @dashboardGetStartedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pour bien démarrer'**
  String get dashboardGetStartedTitle;

  /// No description provided for @dashboardStepAccountsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute tes comptes'**
  String get dashboardStepAccountsTitle;

  /// No description provided for @dashboardStepAccountsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Espèces, Wave, Orange Money, banque…'**
  String get dashboardStepAccountsSubtitle;

  /// No description provided for @dashboardStepTransactionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisis tes premières opérations'**
  String get dashboardStepTransactionsTitle;

  /// No description provided for @dashboardStepTransactionsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Une dépense, un revenu, un transfert'**
  String get dashboardStepTransactionsSubtitle;

  /// No description provided for @dashboardStepBudgetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fixe un premier budget'**
  String get dashboardStepBudgetTitle;

  /// No description provided for @dashboardStepBudgetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Par exemple pour l\'alimentation'**
  String get dashboardStepBudgetSubtitle;

  /// No description provided for @dashboardCopilotHint.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux aussi l\'écrire simplement : « J\'ai 25 000 FCFA sur Wave ».'**
  String get dashboardCopilotHint;

  /// No description provided for @dashboardCopilotAction.
  ///
  /// In fr, this message translates to:
  /// **'Écrire au Copilote'**
  String get dashboardCopilotAction;

  /// No description provided for @dashboardPrivacyNote.
  ///
  /// In fr, this message translates to:
  /// **'Tes données restent sur ce téléphone. Les prévisions apparaîtront après environ deux semaines d\'opérations.'**
  String get dashboardPrivacyNote;

  /// No description provided for @currencyLabel.
  ///
  /// In fr, this message translates to:
  /// **'FCFA'**
  String get currencyLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
