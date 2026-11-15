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
  /// **'Tu peux aussi l\'écrire simplement : « J\'ai 25 000 FCFA sur Wave ».'**
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

  /// No description provided for @dashboardAccountsLink.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Réparti sur 1 compte} other{Répartis sur {count} comptes}}'**
  String dashboardAccountsLink(int count);

  /// No description provided for @currencyLabel.
  ///
  /// In fr, this message translates to:
  /// **'FCFA'**
  String get currencyLabel;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessaie.'**
  String get errorGeneric;

  /// No description provided for @accountTypeCash.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get accountTypeCash;

  /// No description provided for @accountTypeMobileMoney.
  ///
  /// In fr, this message translates to:
  /// **'Mobile Money'**
  String get accountTypeMobileMoney;

  /// No description provided for @accountTypeBank.
  ///
  /// In fr, this message translates to:
  /// **'Banque'**
  String get accountTypeBank;

  /// No description provided for @accountTypeSavings.
  ///
  /// In fr, this message translates to:
  /// **'Épargne'**
  String get accountTypeSavings;

  /// No description provided for @accountsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes comptes'**
  String get accountsTitle;

  /// No description provided for @accountsAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un compte'**
  String get accountsAdd;

  /// No description provided for @accountsTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total des comptes'**
  String get accountsTotal;

  /// No description provided for @accountsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun compte} =1{1 compte} other{{count} comptes}}'**
  String accountsCount(int count);

  /// No description provided for @accountsDistribution.
  ///
  /// In fr, this message translates to:
  /// **'Répartition : {parts}'**
  String accountsDistribution(String parts);

  /// No description provided for @accountsShare.
  ///
  /// In fr, this message translates to:
  /// **'{name} {percent} %'**
  String accountsShare(String name, int percent);

  /// No description provided for @accountsOthers.
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get accountsOthers;

  /// No description provided for @accountsArchived.
  ///
  /// In fr, this message translates to:
  /// **'Archivés'**
  String get accountsArchived;

  /// No description provided for @accountsAddSavings.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un compte épargne'**
  String get accountsAddSavings;

  /// No description provided for @accountsAddSavingsHint.
  ///
  /// In fr, this message translates to:
  /// **'Tontine, livret, coffre…'**
  String get accountsAddSavingsHint;

  /// No description provided for @accountsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte pour l\'instant.'**
  String get accountsEmpty;

  /// No description provided for @accountNoOperation.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération pour l\'instant'**
  String get accountNoOperation;

  /// No description provided for @accountArchivedOn.
  ///
  /// In fr, this message translates to:
  /// **'Archivé le {date} · historique conservé'**
  String accountArchivedOn(String date);

  /// No description provided for @accountNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau compte'**
  String get accountNewTitle;

  /// No description provided for @accountEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le compte'**
  String get accountEditTitle;

  /// No description provided for @accountCreatedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé'**
  String get accountCreatedTitle;

  /// No description provided for @accountFieldType.
  ///
  /// In fr, this message translates to:
  /// **'Type de compte'**
  String get accountFieldType;

  /// No description provided for @accountFieldOperator.
  ///
  /// In fr, this message translates to:
  /// **'Opérateur'**
  String get accountFieldOperator;

  /// No description provided for @accountFieldName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du compte'**
  String get accountFieldName;

  /// No description provided for @accountFieldCurrentBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde actuel'**
  String get accountFieldCurrentBalance;

  /// No description provided for @accountFieldOpeningBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde initial'**
  String get accountFieldOpeningBalance;

  /// No description provided for @accountOpeningBalanceHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ce montant de départ n\'est pas compté comme un revenu.'**
  String get accountOpeningBalanceHelp;

  /// No description provided for @accountNameHintNone.
  ///
  /// In fr, this message translates to:
  /// **'Choisis d\'abord un type'**
  String get accountNameHintNone;

  /// No description provided for @accountNameHintCash.
  ///
  /// In fr, this message translates to:
  /// **'Portefeuille'**
  String get accountNameHintCash;

  /// No description provided for @accountNameHintMobileMoney.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : Wave'**
  String get accountNameHintMobileMoney;

  /// No description provided for @accountNameHintBank.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : Ecobank'**
  String get accountNameHintBank;

  /// No description provided for @accountNameHintSavings.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : Tontine du quartier'**
  String get accountNameHintSavings;

  /// No description provided for @accountCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer le compte'**
  String get accountCreate;

  /// No description provided for @accountSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get accountSave;

  /// No description provided for @accountCreatedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Compte « {name} » créé'**
  String accountCreatedMessage(String name);

  /// No description provided for @accountCreatedBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde de départ : {amount} FCFA'**
  String accountCreatedBalance(String amount);

  /// No description provided for @accountSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes comptes'**
  String get accountSeeAll;

  /// No description provided for @accountAddAnother.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un autre compte'**
  String get accountAddAnother;

  /// No description provided for @accountErrorNameMissing.
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom au compte.'**
  String get accountErrorNameMissing;

  /// No description provided for @accountErrorNameTooLong.
  ///
  /// In fr, this message translates to:
  /// **'40 caractères maximum.'**
  String get accountErrorNameTooLong;

  /// No description provided for @accountErrorNameTaken.
  ///
  /// In fr, this message translates to:
  /// **'Tu as déjà un compte actif à ce nom.'**
  String get accountErrorNameTaken;

  /// No description provided for @accountErrorOpeningBalance.
  ///
  /// In fr, this message translates to:
  /// **'Montant trop élevé.'**
  String get accountErrorOpeningBalance;

  /// No description provided for @accountErrorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte n\'existe plus.'**
  String get accountErrorNotFound;

  /// No description provided for @accountEditAction.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get accountEditAction;

  /// No description provided for @accountTypeAndName.
  ///
  /// In fr, this message translates to:
  /// **'{type} · {name}'**
  String accountTypeAndName(String type, String name);

  /// No description provided for @accountOpeningInfo.
  ///
  /// In fr, this message translates to:
  /// **'Solde initial : {amount} FCFA, saisi le {date}.'**
  String accountOpeningInfo(String amount, String date);

  /// No description provided for @accountArchivedInfo.
  ///
  /// In fr, this message translates to:
  /// **'Archivé le {date}. Il n\'apparaît plus dans tes listes ni dans ton total.'**
  String accountArchivedInfo(String date);

  /// No description provided for @accountArchive.
  ///
  /// In fr, this message translates to:
  /// **'Archiver ce compte'**
  String get accountArchive;

  /// No description provided for @accountRestore.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer ce compte'**
  String get accountRestore;

  /// No description provided for @accountRestored.
  ///
  /// In fr, this message translates to:
  /// **'Compte restauré.'**
  String get accountRestored;

  /// No description provided for @accountRestoreNameTaken.
  ///
  /// In fr, this message translates to:
  /// **'Un compte actif porte déjà ce nom : renomme celui-ci avant de le restaurer.'**
  String get accountRestoreNameTaken;

  /// No description provided for @accountDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce compte'**
  String get accountDelete;

  /// No description provided for @accountArchiveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Archiver le compte {name} ?'**
  String accountArchiveTitle(String name);

  /// No description provided for @accountArchiveBody.
  ///
  /// In fr, this message translates to:
  /// **'Il disparaît de tes listes et de ton total, mais son historique reste consultable dans Comptes › Archivés. Tu pourras le restaurer à tout moment.'**
  String get accountArchiveBody;

  /// No description provided for @accountArchiveConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Archiver'**
  String get accountArchiveConfirm;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte {name} ?'**
  String accountDeleteTitle(String name);

  /// No description provided for @accountDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Ton solde total baissera de {amount} FCFA. Cette action est définitive. Pour garder l\'historique, archive-le plutôt.'**
  String accountDeleteBody(String amount);

  /// No description provided for @accountDeleteBodyArchived.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive : son historique sera perdu.'**
  String get accountDeleteBodyArchived;

  /// No description provided for @accountDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get accountDeleteConfirm;
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
