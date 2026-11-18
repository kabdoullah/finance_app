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

  /// No description provided for @accountDeleteBodyWithOperations.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Son opération sera aussi supprimée} other{Ses {count} opérations seront aussi supprimées}} et ton solde total baissera de {amount} FCFA. Cette action est définitive. Pour garder l\'historique, archive-le plutôt.'**
  String accountDeleteBodyWithOperations(int count, String amount);

  /// No description provided for @accountLastOperation.
  ///
  /// In fr, this message translates to:
  /// **'Dernière opération : {when}'**
  String accountLastOperation(String when);

  /// No description provided for @accountMonthIn.
  ///
  /// In fr, this message translates to:
  /// **'Arrivées en {month}'**
  String accountMonthIn(String month);

  /// No description provided for @accountMonthOut.
  ///
  /// In fr, this message translates to:
  /// **'Sorties en {month}'**
  String accountMonthOut(String month);

  /// No description provided for @accountTransfersNote.
  ///
  /// In fr, this message translates to:
  /// **'Dont {amount} FCFA de transferts entre tes comptes, exclus de tes revenus et dépenses.'**
  String accountTransfersNote(String amount);

  /// No description provided for @accountHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des mouvements'**
  String get accountHistory;

  /// No description provided for @accountNoHistory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun mouvement pour l\'instant.'**
  String get accountNoHistory;

  /// No description provided for @accountNewOperation.
  ///
  /// In fr, this message translates to:
  /// **'Opération'**
  String get accountNewOperation;

  /// No description provided for @accountNewTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Transférer'**
  String get accountNewTransfer;

  /// No description provided for @accountBalanceAfterShort.
  ///
  /// In fr, this message translates to:
  /// **'Solde {amount}'**
  String accountBalanceAfterShort(String amount);

  /// No description provided for @accountInternalTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Transfert interne'**
  String get accountInternalTransfer;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'aujourd\'hui'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'hier'**
  String get yesterday;

  /// No description provided for @dayToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get dayToday;

  /// No description provided for @dayYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get dayYesterday;

  /// No description provided for @dayHeaderRelative.
  ///
  /// In fr, this message translates to:
  /// **'{day} · {date}'**
  String dayHeaderRelative(String day, String date);

  /// No description provided for @atTime.
  ///
  /// In fr, this message translates to:
  /// **'{day} à {time}'**
  String atTime(String day, String time);

  /// No description provided for @txKindExpense.
  ///
  /// In fr, this message translates to:
  /// **'Dépense'**
  String get txKindExpense;

  /// No description provided for @txKindIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenu'**
  String get txKindIncome;

  /// No description provided for @txKindTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Transfert'**
  String get txKindTransfer;

  /// No description provided for @txKindExpenseHint.
  ///
  /// In fr, this message translates to:
  /// **'Achat, facture, retrait'**
  String get txKindExpenseHint;

  /// No description provided for @txKindIncomeHint.
  ///
  /// In fr, this message translates to:
  /// **'Salaire, vente, argent reçu'**
  String get txKindIncomeHint;

  /// No description provided for @txKindTransferHint.
  ///
  /// In fr, this message translates to:
  /// **'Entre deux de tes comptes'**
  String get txKindTransferHint;

  /// No description provided for @txAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get txAdd;

  /// No description provided for @txNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle opération'**
  String get txNewTitle;

  /// No description provided for @txSavedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Opération enregistrée'**
  String get txSavedTitle;

  /// No description provided for @txAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get txAmount;

  /// No description provided for @txContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get txContinue;

  /// No description provided for @txChange.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get txChange;

  /// No description provided for @txCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get txCategory;

  /// No description provided for @txSubcategory.
  ///
  /// In fr, this message translates to:
  /// **'Sous-catégorie'**
  String get txSubcategory;

  /// No description provided for @txNoSubcategory.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get txNoSubcategory;

  /// No description provided for @txAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get txAccount;

  /// No description provided for @txFrom.
  ///
  /// In fr, this message translates to:
  /// **'Depuis'**
  String get txFrom;

  /// No description provided for @txTo.
  ///
  /// In fr, this message translates to:
  /// **'Vers'**
  String get txTo;

  /// No description provided for @txDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get txDate;

  /// No description provided for @txDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get txDescription;

  /// No description provided for @txAddDescription.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une description'**
  String get txAddDescription;

  /// No description provided for @txDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : taxi pour le bureau'**
  String get txDescriptionHint;

  /// No description provided for @txTransferInfo.
  ///
  /// In fr, this message translates to:
  /// **'Un transfert entre tes comptes ne compte ni comme revenu ni comme dépense : ton solde total ne change pas.'**
  String get txTransferInfo;

  /// No description provided for @txSaveExpense.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la dépense'**
  String get txSaveExpense;

  /// No description provided for @txSaveIncome.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le revenu'**
  String get txSaveIncome;

  /// No description provided for @txSaveTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le transfert'**
  String get txSaveTransfer;

  /// No description provided for @txSavedExpense.
  ///
  /// In fr, this message translates to:
  /// **'Dépense enregistrée'**
  String get txSavedExpense;

  /// No description provided for @txSavedIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenu enregistré'**
  String get txSavedIncome;

  /// No description provided for @txSavedTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Transfert enregistré'**
  String get txSavedTransfer;

  /// No description provided for @txNewBalance.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau solde {account}'**
  String txNewBalance(String account);

  /// No description provided for @txBackHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get txBackHome;

  /// No description provided for @txAddAnother.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une autre opération'**
  String get txAddAnother;

  /// No description provided for @txNeedAccount.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute d\'abord un compte pour enregistrer une opération.'**
  String get txNeedAccount;

  /// No description provided for @txNeedTwoAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Il faut au moins deux comptes actifs pour faire un transfert.'**
  String get txNeedTwoAccounts;

  /// No description provided for @txChooseAccount.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un compte'**
  String get txChooseAccount;

  /// No description provided for @txAccountUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte n\'est plus disponible : choisis-en un autre.'**
  String get txAccountUnavailable;

  /// No description provided for @txTransferTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vers {account}'**
  String txTransferTitle(String account);

  /// No description provided for @txTransferMeta.
  ///
  /// In fr, this message translates to:
  /// **'Transfert · {from} → {to}'**
  String txTransferMeta(String from, String to);

  /// No description provided for @txMeta.
  ///
  /// In fr, this message translates to:
  /// **'{category} · {account}'**
  String txMeta(String category, String account);

  /// No description provided for @txListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Transactions'**
  String get txListTitle;

  /// No description provided for @txSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une opération'**
  String get txSearchHint;

  /// No description provided for @txClearSearch.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la recherche'**
  String get txClearSearch;

  /// No description provided for @txFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get txFilterAll;

  /// No description provided for @txFilterIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get txFilterIncome;

  /// No description provided for @txFilterExpense.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get txFilterExpense;

  /// No description provided for @txFilterTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Transferts'**
  String get txFilterTransfer;

  /// No description provided for @txCountSummary.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune opération} =1{1 opération} other{{count} opérations}} · transferts exclus des totaux'**
  String txCountSummary(int count);

  /// No description provided for @txEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération pour l\'instant'**
  String get txEmptyTitle;

  /// No description provided for @txEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ta première dépense ou ton premier revenu. Tu peux aussi l\'écrire au Copilote : « Taxi 2 500 avec Wave ».'**
  String get txEmptyBody;

  /// No description provided for @txEmptyAction.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une opération'**
  String get txEmptyAction;

  /// No description provided for @txMonthEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération en {month}.'**
  String txMonthEmpty(String month);

  /// No description provided for @txNoResultTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get txNoResultTitle;

  /// No description provided for @txNoResultBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération ne correspond à « {query} » en {month}. Essaie un autre mot ou change de période.'**
  String txNoResultBody(String query, String month);

  /// No description provided for @txChooseMonth.
  ///
  /// In fr, this message translates to:
  /// **'Choisir le mois'**
  String get txChooseMonth;

  /// No description provided for @txAllAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Tous les comptes'**
  String get txAllAccounts;

  /// No description provided for @txAllCategories.
  ///
  /// In fr, this message translates to:
  /// **'Toutes catégories'**
  String get txAllCategories;

  /// No description provided for @txChooseCategory.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une catégorie'**
  String get txChooseCategory;

  /// No description provided for @txFilterExpenseSection.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get txFilterExpenseSection;

  /// No description provided for @txFilterIncomeSection.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get txFilterIncomeSection;

  /// No description provided for @txArchivedAccount.
  ///
  /// In fr, this message translates to:
  /// **'{name} (archivé)'**
  String txArchivedAccount(String name);

  /// No description provided for @txNoFilterMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération ne correspond à ces filtres en {month}.'**
  String txNoFilterMatch(String month);

  /// No description provided for @txResetFilters.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser les filtres'**
  String get txResetFilters;

  /// No description provided for @settingsCategoriesHint.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses et revenus, sous-catégories'**
  String get settingsCategoriesHint;

  /// No description provided for @categoriesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categoriesTitle;

  /// No description provided for @categoriesNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle catégorie'**
  String get categoriesNew;

  /// No description provided for @categoriesNewSub.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle sous-catégorie'**
  String get categoriesNewSub;

  /// No description provided for @categoryCustom.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisée'**
  String get categoryCustom;

  /// No description provided for @categoryHidden.
  ///
  /// In fr, this message translates to:
  /// **'Masquée'**
  String get categoryHidden;

  /// No description provided for @categorySubCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune sous-catégorie} =1{1 sous-catégorie} other{{count} sous-catégories}}'**
  String categorySubCount(int count);

  /// No description provided for @categoryAddSub.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get categoryAddSub;

  /// No description provided for @categoriesFootnote.
  ///
  /// In fr, this message translates to:
  /// **'Les catégories prédéfinies ne peuvent pas être supprimées, seulement masquées. Une catégorie personnalisée supprimée renvoie ses opérations vers « Autre ».'**
  String get categoriesFootnote;

  /// No description provided for @categoryName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get categoryName;

  /// No description provided for @categoryNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : Tontine, Cadeaux, Moto'**
  String get categoryNameHint;

  /// No description provided for @categoryAttachTo.
  ///
  /// In fr, this message translates to:
  /// **'Rattacher à'**
  String get categoryAttachTo;

  /// No description provided for @categoryNoParent.
  ///
  /// In fr, this message translates to:
  /// **'Aucune (principale)'**
  String get categoryNoParent;

  /// No description provided for @categoryIcon.
  ///
  /// In fr, this message translates to:
  /// **'Icône'**
  String get categoryIcon;

  /// No description provided for @categoryCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer la catégorie'**
  String get categoryCreate;

  /// No description provided for @categoryAddTo.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à {parent}'**
  String categoryAddTo(String parent);

  /// No description provided for @categoryCreated.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie « {name} » créée.'**
  String categoryCreated(String name);

  /// No description provided for @categorySubCreated.
  ///
  /// In fr, this message translates to:
  /// **'Sous-catégorie « {name} » ajoutée à {parent}.'**
  String categorySubCreated(String name, String parent);

  /// No description provided for @categoryRename.
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get categoryRename;

  /// No description provided for @categoryRenameTitle.
  ///
  /// In fr, this message translates to:
  /// **'Renommer « {name} »'**
  String categoryRenameTitle(String name);

  /// No description provided for @categoryHide.
  ///
  /// In fr, this message translates to:
  /// **'Masquer'**
  String get categoryHide;

  /// No description provided for @categoryShow.
  ///
  /// In fr, this message translates to:
  /// **'Réafficher'**
  String get categoryShow;

  /// No description provided for @categoryDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get categoryDelete;

  /// No description provided for @categoryHiddenToast.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » est masquée : elle n\'est plus proposée à la saisie.'**
  String categoryHiddenToast(String name);

  /// No description provided for @categoryShownToast.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » est de nouveau proposée.'**
  String categoryShownToast(String name);

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {name} » ?'**
  String categoryDeleteTitle(String name);

  /// No description provided for @categoryDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune opération ne l\'utilise.} =1{Son opération passera dans « {target} ».} other{Ses {count} opérations passeront dans « {target} ».}} Cette action est définitive.'**
  String categoryDeleteBody(int count, String target);

  /// No description provided for @categoryDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie supprimée.'**
  String get categoryDeleted;

  /// No description provided for @categoryErrorNameMissing.
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom à la catégorie.'**
  String get categoryErrorNameMissing;

  /// No description provided for @categoryErrorNameTooLong.
  ///
  /// In fr, this message translates to:
  /// **'40 caractères maximum.'**
  String get categoryErrorNameTooLong;

  /// No description provided for @categoryErrorNameTaken.
  ///
  /// In fr, this message translates to:
  /// **'Une catégorie porte déjà ce nom ici.'**
  String get categoryErrorNameTaken;

  /// No description provided for @categoryIconLabel.
  ///
  /// In fr, this message translates to:
  /// **'{key, select, tag{Étiquette} gift{Cadeau} hand_coins{Argent} device_mobile{Téléphone} heartbeat{Santé} graduation_cap{Études} users{Famille} t_shirt{Vêtements} house_line{Maison} ticket{Sortie} taxi{Transport} basket{Courses} other{Icône}}'**
  String categoryIconLabel(String key);

  /// No description provided for @budgetsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Budgets'**
  String get budgetsTitle;

  /// No description provided for @budgetMonthTitle.
  ///
  /// In fr, this message translates to:
  /// **'Budget de {month}'**
  String budgetMonthTitle(String month);

  /// No description provided for @budgetOfLimit.
  ///
  /// In fr, this message translates to:
  /// **'/ {limit} FCFA'**
  String budgetOfLimit(String limit);

  /// No description provided for @budgetRemainingSentence.
  ///
  /// In fr, this message translates to:
  /// **'Il te reste {amount} FCFA jusqu\'à la fin du mois, soit environ {perDay} FCFA par jour.'**
  String budgetRemainingSentence(String amount, String perDay);

  /// No description provided for @budgetOverSentence.
  ///
  /// In fr, this message translates to:
  /// **'Budget du mois dépassé de {amount} FCFA.'**
  String budgetOverSentence(String amount);

  /// No description provided for @budgetDaysLeft.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Dernier jour} other{Encore {count} jours}}'**
  String budgetDaysLeft(int count);

  /// No description provided for @budgetNoGlobal.
  ///
  /// In fr, this message translates to:
  /// **'Définir un budget pour tout le mois'**
  String get budgetNoGlobal;

  /// No description provided for @budgetExceededAlert.
  ///
  /// In fr, this message translates to:
  /// **'{name} : budget dépassé de {amount} FCFA.'**
  String budgetExceededAlert(String name, String amount);

  /// No description provided for @budgetByCategory.
  ///
  /// In fr, this message translates to:
  /// **'Par catégorie'**
  String get budgetByCategory;

  /// No description provided for @budgetDriver.
  ///
  /// In fr, this message translates to:
  /// **'Surtout à cause de {name} : {count, plural, =1{1 opération} other{{count} opérations}}, {amount} FCFA ce mois-ci.'**
  String budgetDriver(String name, int count, String amount);

  /// No description provided for @budgetForecastLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prévision :'**
  String get budgetForecastLabel;

  /// No description provided for @budgetForecastLead.
  ///
  /// In fr, this message translates to:
  /// **'au rythme actuel, {items}.'**
  String budgetForecastLead(String items);

  /// No description provided for @budgetForecastCategory.
  ///
  /// In fr, this message translates to:
  /// **'{name} dépassera son budget vers le {date}'**
  String budgetForecastCategory(String name, String date);

  /// No description provided for @budgetForecastGlobal.
  ///
  /// In fr, this message translates to:
  /// **'le budget du mois sera dépassé vers le {date}'**
  String budgetForecastGlobal(String date);

  /// No description provided for @listAnd.
  ///
  /// In fr, this message translates to:
  /// **'et'**
  String get listAnd;

  /// No description provided for @budgetSpentOf.
  ///
  /// In fr, this message translates to:
  /// **'{spent} sur {limit}'**
  String budgetSpentOf(String spent, String limit);

  /// No description provided for @budgetRemaining.
  ///
  /// In fr, this message translates to:
  /// **'{amount} restants'**
  String budgetRemaining(String amount);

  /// No description provided for @budgetExceeded.
  ///
  /// In fr, this message translates to:
  /// **'Dépassé de {amount}'**
  String budgetExceeded(String amount);

  /// No description provided for @budgetPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get budgetPaid;

  /// No description provided for @budgetWithout.
  ///
  /// In fr, this message translates to:
  /// **'Sans budget : {names}'**
  String budgetWithout(String names);

  /// No description provided for @budgetCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer un budget'**
  String get budgetCreate;

  /// No description provided for @budgetSeeOperations.
  ///
  /// In fr, this message translates to:
  /// **'Voir les opérations'**
  String get budgetSeeOperations;

  /// No description provided for @budgetEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun budget pour l\'instant. Fixe une limite par mois pour suivre tes dépenses.'**
  String get budgetEmpty;

  /// No description provided for @budgetNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Création d\'un budget'**
  String get budgetNewTitle;

  /// No description provided for @budgetEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le budget'**
  String get budgetEditTitle;

  /// No description provided for @budgetAllExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les dépenses'**
  String get budgetAllExpenses;

  /// No description provided for @budgetAlreadyTracked.
  ///
  /// In fr, this message translates to:
  /// **'Déjà suivies : {names}'**
  String budgetAlreadyTracked(String names);

  /// No description provided for @budgetLimit.
  ///
  /// In fr, this message translates to:
  /// **'Limite par mois'**
  String get budgetLimit;

  /// No description provided for @budgetAverage.
  ///
  /// In fr, this message translates to:
  /// **'Ces 3 derniers mois, tu as dépensé en moyenne {amount} FCFA.'**
  String budgetAverage(String amount);

  /// No description provided for @budgetUseAmount.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ce montant'**
  String get budgetUseAmount;

  /// No description provided for @budgetPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get budgetPeriod;

  /// No description provided for @budgetPeriodMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Chaque mois, à partir du 1er'**
  String get budgetPeriodMonthly;

  /// No description provided for @budgetAlertAt.
  ///
  /// In fr, this message translates to:
  /// **'M\'avertir quand j\'atteins'**
  String get budgetAlertAt;

  /// No description provided for @budgetSave.
  ///
  /// In fr, this message translates to:
  /// **'Créer le budget'**
  String get budgetSave;

  /// No description provided for @budgetCreatedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Budget créé'**
  String get budgetCreatedTitle;

  /// No description provided for @budgetCreatedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Budget {name} créé'**
  String budgetCreatedMessage(String name);

  /// No description provided for @budgetCreatedGlobal.
  ///
  /// In fr, this message translates to:
  /// **'Budget du mois créé'**
  String get budgetCreatedGlobal;

  /// No description provided for @budgetCreatedDetail.
  ///
  /// In fr, this message translates to:
  /// **'{amount} FCFA par mois · alerte à {percent} %'**
  String budgetCreatedDetail(String amount, int percent);

  /// No description provided for @budgetSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes budgets'**
  String get budgetSeeAll;

  /// No description provided for @budgetAddAnother.
  ///
  /// In fr, this message translates to:
  /// **'Créer un autre budget'**
  String get budgetAddAnother;

  /// No description provided for @budgetSaveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get budgetSaveChanges;

  /// No description provided for @budgetDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Budget supprimé.'**
  String get budgetDeleted;

  /// No description provided for @budgetErrorLimit.
  ///
  /// In fr, this message translates to:
  /// **'Indique une limite supérieure à 0.'**
  String get budgetErrorLimit;

  /// No description provided for @budgetErrorExists.
  ///
  /// In fr, this message translates to:
  /// **'Cette catégorie a déjà un budget.'**
  String get budgetErrorExists;

  /// No description provided for @budgetErrorCategory.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une catégorie de dépenses.'**
  String get budgetErrorCategory;

  /// No description provided for @budgetDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce budget'**
  String get budgetDelete;

  /// No description provided for @budgetDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce budget ?'**
  String get budgetDeleteTitle;

  /// No description provided for @budgetDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Tes opérations ne sont pas modifiées : seul le suivi de la limite disparaît.'**
  String get budgetDeleteBody;

  /// No description provided for @budgetImpactLeft.
  ///
  /// In fr, this message translates to:
  /// **'Il te reste {amount} FCFA dans ton budget {name}.'**
  String budgetImpactLeft(String amount, String name);

  /// No description provided for @budgetImpactOver.
  ///
  /// In fr, this message translates to:
  /// **'Ton budget {name} est maintenant dépassé de {amount} FCFA.'**
  String budgetImpactOver(String name, String amount);

  /// No description provided for @dashboardWhereMoney.
  ///
  /// In fr, this message translates to:
  /// **'Où va ton argent'**
  String get dashboardWhereMoney;

  /// No description provided for @dashboardShare.
  ///
  /// In fr, this message translates to:
  /// **'{percent} %'**
  String dashboardShare(int percent);

  /// No description provided for @txDetailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Opération'**
  String get txDetailTitle;

  /// No description provided for @txKindWhen.
  ///
  /// In fr, this message translates to:
  /// **'{kind} · {when}'**
  String txKindWhen(String kind, String when);

  /// No description provided for @txBalanceAfter.
  ///
  /// In fr, this message translates to:
  /// **'Solde après : {amount} FCFA'**
  String txBalanceAfter(String amount);

  /// No description provided for @txEntry.
  ///
  /// In fr, this message translates to:
  /// **'Saisie'**
  String get txEntry;

  /// No description provided for @entryManual.
  ///
  /// In fr, this message translates to:
  /// **'Manuelle'**
  String get entryManual;

  /// No description provided for @entryVoice.
  ///
  /// In fr, this message translates to:
  /// **'Vocale'**
  String get entryVoice;

  /// No description provided for @entryText.
  ///
  /// In fr, this message translates to:
  /// **'Texte'**
  String get entryText;

  /// No description provided for @entryReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Reçu'**
  String get entryReceipt;

  /// No description provided for @entryRecurring.
  ///
  /// In fr, this message translates to:
  /// **'Récurrente'**
  String get entryRecurring;

  /// No description provided for @txDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer'**
  String get txDuplicate;

  /// No description provided for @txDuplicated.
  ///
  /// In fr, this message translates to:
  /// **'Opération dupliquée.'**
  String get txDuplicated;

  /// No description provided for @txDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get txDelete;

  /// No description provided for @txDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'{kind, select, expense{Supprimer cette dépense ?} income{Supprimer ce revenu ?} other{Supprimer ce transfert ?}}'**
  String txDeleteTitle(String kind);

  /// No description provided for @txDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'{title}, {amount} FCFA. Le solde {account} sera recalculé.'**
  String txDeleteBody(String title, String amount, String account);

  /// No description provided for @txDeletedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Opération supprimée'**
  String get txDeletedTitle;

  /// No description provided for @txDeletedBody.
  ///
  /// In fr, this message translates to:
  /// **'Le solde {account} a été mis à jour.'**
  String txDeletedBody(String account);

  /// No description provided for @txUndo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la suppression'**
  String get txUndo;

  /// No description provided for @txBackToList.
  ///
  /// In fr, this message translates to:
  /// **'Retour aux transactions'**
  String get txBackToList;

  /// No description provided for @txNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Cette opération n\'existe plus.'**
  String get txNotFound;

  /// No description provided for @dashboardMonthIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenus du mois'**
  String get dashboardMonthIncome;

  /// No description provided for @dashboardMonthExpense.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses du mois'**
  String get dashboardMonthExpense;

  /// No description provided for @dashboardRecent.
  ///
  /// In fr, this message translates to:
  /// **'Dernières opérations'**
  String get dashboardRecent;

  /// No description provided for @dashboardSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get dashboardSeeAll;

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
