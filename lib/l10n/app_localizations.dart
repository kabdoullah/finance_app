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
  /// **'Finao'**
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

  /// No description provided for @accountOpeningBalanceLocked.
  ///
  /// In fr, this message translates to:
  /// **'Le solde initial ne peut plus être modifié après la création du compte.'**
  String get accountOpeningBalanceLocked;

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

  /// No description provided for @qeDictate.
  ///
  /// In fr, this message translates to:
  /// **'Dicter'**
  String get qeDictate;

  /// No description provided for @qeDictateHint.
  ///
  /// In fr, this message translates to:
  /// **'Une ou plusieurs opérations'**
  String get qeDictateHint;

  /// No description provided for @qeWrite.
  ///
  /// In fr, this message translates to:
  /// **'Écrire'**
  String get qeWrite;

  /// No description provided for @qeOrWrite.
  ///
  /// In fr, this message translates to:
  /// **'Ou écris-le simplement'**
  String get qeOrWrite;

  /// No description provided for @qeWriteExample.
  ///
  /// In fr, this message translates to:
  /// **'« Taxi 2 500 ce matin avec Wave »'**
  String get qeWriteExample;

  /// No description provided for @qeWriteNote.
  ///
  /// In fr, this message translates to:
  /// **'L\'application prépare les opérations, tu vérifies avant d\'enregistrer.'**
  String get qeWriteNote;

  /// No description provided for @qeListening.
  ///
  /// In fr, this message translates to:
  /// **'Écoute en cours · reconnaissance hors ligne'**
  String get qeListening;

  /// No description provided for @qeListenHint.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux dicter plusieurs opérations d\'un coup, avec le compte et la date : « Hier, 2 000 de crédit Orange et 1 500 de pain en espèces ».'**
  String get qeListenHint;

  /// No description provided for @qeTapToFinish.
  ///
  /// In fr, this message translates to:
  /// **'Touche pour terminer'**
  String get qeTapToFinish;

  /// No description provided for @qeTapToRetry.
  ///
  /// In fr, this message translates to:
  /// **'Touche pour réessayer'**
  String get qeTapToRetry;

  /// No description provided for @qeInputPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Décris tes opérations avec tes mots'**
  String get qeInputPrompt;

  /// No description provided for @qeExamples.
  ///
  /// In fr, this message translates to:
  /// **'Exemples'**
  String get qeExamples;

  /// No description provided for @qeExample1.
  ///
  /// In fr, this message translates to:
  /// **'Déjeuner 2 500 et taxi 1 000 avec Wave'**
  String get qeExample1;

  /// No description provided for @qeExample2.
  ///
  /// In fr, this message translates to:
  /// **'Reçu 45 000 de mon client sur Orange Money'**
  String get qeExample2;

  /// No description provided for @qeExample3.
  ///
  /// In fr, this message translates to:
  /// **'Hier, recharge crédit 2 000 en espèces'**
  String get qeExample3;

  /// No description provided for @qeAnalyse.
  ///
  /// In fr, this message translates to:
  /// **'Analyser'**
  String get qeAnalyse;

  /// No description provided for @qeRecapHeading.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get qeRecapHeading;

  /// No description provided for @qeRecapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif à vérifier'**
  String get qeRecapTitle;

  /// No description provided for @qeSimplified.
  ///
  /// In fr, this message translates to:
  /// **'Analyse simplifiée par l\'application : vérifie bien chaque champ.'**
  String get qeSimplified;

  /// No description provided for @qeCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune opération détectée} =1{1 opération détectée} other{{count} opérations détectées}}'**
  String qeCount(int count);

  /// No description provided for @qeToCheck.
  ///
  /// In fr, this message translates to:
  /// **'À vérifier'**
  String get qeToCheck;

  /// No description provided for @qeAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get qeAmount;

  /// No description provided for @qeDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get qeDescription;

  /// No description provided for @qeAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get qeAccount;

  /// No description provided for @qeFrom.
  ///
  /// In fr, this message translates to:
  /// **'Depuis'**
  String get qeFrom;

  /// No description provided for @qeTo.
  ///
  /// In fr, this message translates to:
  /// **'Vers'**
  String get qeTo;

  /// No description provided for @qeDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get qeDate;

  /// No description provided for @qeDayBeforeYesterday.
  ///
  /// In fr, this message translates to:
  /// **'avant-hier'**
  String get qeDayBeforeYesterday;

  /// No description provided for @qeRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cette opération'**
  String get qeRemove;

  /// No description provided for @qeAddOperation.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une opération'**
  String get qeAddOperation;

  /// No description provided for @qeTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get qeTotal;

  /// No description provided for @qeSave.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Enregistrer l\'opération} other{Enregistrer {count} opérations}}'**
  String qeSave(int count);

  /// No description provided for @qeNothingSaved.
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'est enregistré avant ta confirmation.'**
  String get qeNothingSaved;

  /// No description provided for @qeSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'L\'enregistrement a échoué. Vérifie les opérations et réessaie.'**
  String get qeSaveFailed;

  /// No description provided for @qeDoneHeading.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré'**
  String get qeDoneHeading;

  /// No description provided for @qeDoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Opération enregistrée} other{{count} opérations enregistrées}}'**
  String qeDoneTitle(int count);

  /// No description provided for @qeDoneSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutées à tes opérations.'**
  String get qeDoneSubtitle;

  /// No description provided for @qeSeeTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Voir dans Transactions'**
  String get qeSeeTransactions;

  /// No description provided for @qeDictateAnother.
  ///
  /// In fr, this message translates to:
  /// **'Dicter une autre opération'**
  String get qeDictateAnother;

  /// No description provided for @qeWriteAnother.
  ///
  /// In fr, this message translates to:
  /// **'Écrire une autre opération'**
  String get qeWriteAnother;

  /// No description provided for @qeNothingHeard.
  ///
  /// In fr, this message translates to:
  /// **'Je n\'ai rien entendu.'**
  String get qeNothingHeard;

  /// No description provided for @qeNoOperation.
  ///
  /// In fr, this message translates to:
  /// **'Aucun montant trouvé. Ajoute une opération ou réessaie.'**
  String get qeNoOperation;

  /// No description provided for @qeMicDenied.
  ///
  /// In fr, this message translates to:
  /// **'Autorise le micro pour dicter, ou écris tes opérations.'**
  String get qeMicDenied;

  /// No description provided for @qeUnsupported.
  ///
  /// In fr, this message translates to:
  /// **'La dictée hors connexion n\'est pas disponible sur ce téléphone. Écris tes opérations, c\'est aussi rapide.'**
  String get qeUnsupported;

  /// No description provided for @qeLangTitle.
  ///
  /// In fr, this message translates to:
  /// **'Installe le français pour dicter'**
  String get qeLangTitle;

  /// No description provided for @qeLangBody.
  ///
  /// In fr, this message translates to:
  /// **'La dictée se fait sur ton téléphone, sans Internet. Elle a besoin du français hors connexion, à installer une seule fois.'**
  String get qeLangBody;

  /// No description provided for @qeLangInstall.
  ///
  /// In fr, this message translates to:
  /// **'Installer le français'**
  String get qeLangInstall;

  /// No description provided for @qeLangManualIos.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre Réglages › Général › Clavier : active Dictée, puis ajoute le clavier Français. Le français hors connexion se télécharge ensuite automatiquement.'**
  String get qeLangManualIos;

  /// No description provided for @qeLangManual.
  ///
  /// In fr, this message translates to:
  /// **'Si rien ne se passe : ouvre les paramètres de Gboard › Saisie vocale › Reconnaissance hors connexion, puis ajoute Français.'**
  String get qeLangManual;

  /// No description provided for @qeLangCheck.
  ///
  /// In fr, this message translates to:
  /// **'C\'est installé'**
  String get qeLangCheck;

  /// No description provided for @qeWriteInstead.
  ///
  /// In fr, this message translates to:
  /// **'Écrire plutôt'**
  String get qeWriteInstead;

  /// No description provided for @qeLangDownloading.
  ///
  /// In fr, this message translates to:
  /// **'Le français est en cours de téléchargement. Réessaie dans un instant.'**
  String get qeLangDownloading;

  /// No description provided for @aiModelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modèle IA'**
  String get aiModelTitle;

  /// No description provided for @aiModelName.
  ///
  /// In fr, this message translates to:
  /// **'Gemma 4'**
  String get aiModelName;

  /// No description provided for @aiModelMeta.
  ///
  /// In fr, this message translates to:
  /// **'Modèle embarqué · 2,5 Go · français'**
  String get aiModelMeta;

  /// No description provided for @aiStatusChecking.
  ///
  /// In fr, this message translates to:
  /// **'Vérification…'**
  String get aiStatusChecking;

  /// No description provided for @aiStatusUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Indisponible'**
  String get aiStatusUnavailable;

  /// No description provided for @aiStatusNone.
  ///
  /// In fr, this message translates to:
  /// **'Non installé'**
  String get aiStatusNone;

  /// No description provided for @aiStatusDownloading.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement'**
  String get aiStatusDownloading;

  /// No description provided for @aiStatusInstalled.
  ///
  /// In fr, this message translates to:
  /// **'Installé'**
  String get aiStatusInstalled;

  /// No description provided for @aiStatusLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement'**
  String get aiStatusLoading;

  /// No description provided for @aiStatusReady.
  ///
  /// In fr, this message translates to:
  /// **'Prêt'**
  String get aiStatusReady;

  /// No description provided for @aiStatusError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get aiStatusError;

  /// No description provided for @aiDescChecking.
  ///
  /// In fr, this message translates to:
  /// **'Vérification de ton téléphone…'**
  String get aiDescChecking;

  /// No description provided for @aiDescUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'L\'assistant IA n\'est pas disponible sur ce téléphone. L\'application reste complète.'**
  String get aiDescUnavailable;

  /// No description provided for @aiReasonSystem.
  ///
  /// In fr, this message translates to:
  /// **'Il demande une version plus récente du système (Android 11 ou iOS 15 au minimum).'**
  String get aiReasonSystem;

  /// No description provided for @aiReason64Bit.
  ///
  /// In fr, this message translates to:
  /// **'Il demande un téléphone 64 bits.'**
  String get aiReason64Bit;

  /// No description provided for @aiReasonRam.
  ///
  /// In fr, this message translates to:
  /// **'Il demande au moins 6 Go de mémoire.'**
  String get aiReasonRam;

  /// No description provided for @aiDescNone.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement unique de 2,5 Go (Wi-Fi conseillé). Ensuite, tout fonctionne hors connexion.'**
  String get aiDescNone;

  /// No description provided for @aiDescDownloading.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux continuer à utiliser l\'application pendant le téléchargement.'**
  String get aiDescDownloading;

  /// No description provided for @aiDescInstalled.
  ///
  /// In fr, this message translates to:
  /// **'Installé mais pas chargé. Il se charge en quelques secondes à la première question.'**
  String get aiDescInstalled;

  /// No description provided for @aiDescLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du modèle en mémoire, quelques secondes…'**
  String get aiDescLoading;

  /// No description provided for @aiDescReady.
  ///
  /// In fr, this message translates to:
  /// **'Chargé en mémoire. L\'assistant répond hors connexion.'**
  String get aiDescReady;

  /// No description provided for @aiDescError.
  ///
  /// In fr, this message translates to:
  /// **'Le modèle est installé mais n\'a pas pu démarrer.'**
  String get aiDescError;

  /// No description provided for @aiInstall.
  ///
  /// In fr, this message translates to:
  /// **'Installer (2,5 Go)'**
  String get aiInstall;

  /// No description provided for @aiCancelDownload.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le téléchargement'**
  String get aiCancelDownload;

  /// No description provided for @aiLoadNow.
  ///
  /// In fr, this message translates to:
  /// **'Charger maintenant'**
  String get aiLoadNow;

  /// No description provided for @aiUnload.
  ///
  /// In fr, this message translates to:
  /// **'Libérer la mémoire'**
  String get aiUnload;

  /// No description provided for @aiRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get aiRetry;

  /// No description provided for @aiContinueWithout.
  ///
  /// In fr, this message translates to:
  /// **'Continuer sans IA'**
  String get aiContinueWithout;

  /// No description provided for @aiProgress.
  ///
  /// In fr, this message translates to:
  /// **'{received} Go sur 2,5 Go · {percent} %'**
  String aiProgress(String received, int percent);

  /// No description provided for @aiLoadingBar.
  ///
  /// In fr, this message translates to:
  /// **'Chargement en mémoire…'**
  String get aiLoadingBar;

  /// No description provided for @aiLowMemory.
  ///
  /// In fr, this message translates to:
  /// **'Mémoire insuffisante. Il faut environ 2 Go libres. Ferme d\'autres applications puis réessaie.'**
  String get aiLowMemory;

  /// No description provided for @aiDownloadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le téléchargement a échoué. Vérifie ta connexion et réessaie.'**
  String get aiDownloadFailed;

  /// No description provided for @aiNoStorage.
  ///
  /// In fr, this message translates to:
  /// **'Espace insuffisant : il faut environ 3 Go libres sur le téléphone.'**
  String get aiNoStorage;

  /// No description provided for @aiMeteredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'es pas en Wi-Fi'**
  String get aiMeteredTitle;

  /// No description provided for @aiMeteredBody.
  ///
  /// In fr, this message translates to:
  /// **'Le téléchargement utilisera 2,5 Go de données mobiles.'**
  String get aiMeteredBody;

  /// No description provided for @aiMeteredConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger quand même'**
  String get aiMeteredConfirm;

  /// No description provided for @aiRoleGemma.
  ///
  /// In fr, this message translates to:
  /// **'Comprend tes phrases, explique tes chiffres, répond à tes questions.'**
  String get aiRoleGemma;

  /// No description provided for @aiRoleAppTitle.
  ///
  /// In fr, this message translates to:
  /// **'L\'application'**
  String get aiRoleAppTitle;

  /// No description provided for @aiRoleApp.
  ///
  /// In fr, this message translates to:
  /// **'Calcule soldes, budgets, prévisions et simulations.'**
  String get aiRoleApp;

  /// No description provided for @aiWithout.
  ///
  /// In fr, this message translates to:
  /// **'Sans l\'IA, l\'application reste complète : saisie manuelle et vocale, budgets, prévisions. Seules les réponses en langage naturel sont indisponibles.'**
  String get aiWithout;

  /// No description provided for @aiVoiceSection.
  ///
  /// In fr, this message translates to:
  /// **'Reconnaissance vocale'**
  String get aiVoiceSection;

  /// No description provided for @aiVoiceEngine.
  ///
  /// In fr, this message translates to:
  /// **'Moteur de dictée'**
  String get aiVoiceEngine;

  /// No description provided for @aiVoiceEngineHint.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne, distinct de Gemma'**
  String get aiVoiceEngineHint;

  /// No description provided for @aiVoiceReady.
  ///
  /// In fr, this message translates to:
  /// **'Prêt'**
  String get aiVoiceReady;

  /// No description provided for @aiVoiceMissing.
  ///
  /// In fr, this message translates to:
  /// **'Français à installer'**
  String get aiVoiceMissing;

  /// No description provided for @aiVoiceDownloading.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement'**
  String get aiVoiceDownloading;

  /// No description provided for @aiVoiceUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Indisponible'**
  String get aiVoiceUnavailable;

  /// No description provided for @aiVoiceLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue de dictée'**
  String get aiVoiceLanguage;

  /// No description provided for @aiVoiceFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get aiVoiceFrench;

  /// No description provided for @aiPrefsSection.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get aiPrefsSection;

  /// No description provided for @aiLoadOnStartup.
  ///
  /// In fr, this message translates to:
  /// **'Charger l\'IA au démarrage'**
  String get aiLoadOnStartup;

  /// No description provided for @aiLoadOnStartupHint.
  ///
  /// In fr, this message translates to:
  /// **'Réponses plus rapides, un peu plus de mémoire utilisée'**
  String get aiLoadOnStartupHint;

  /// No description provided for @aiDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le modèle'**
  String get aiDelete;

  /// No description provided for @aiDeleteHint.
  ///
  /// In fr, this message translates to:
  /// **'Libère 2,5 Go. Tes données ne sont pas touchées.'**
  String get aiDeleteHint;

  /// No description provided for @aiDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer Gemma 4 ?'**
  String get aiDeleteTitle;

  /// No description provided for @aiDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Le modèle sera retiré du téléphone (2,5 Go libérés). Tes opérations, budgets et objectifs restent intacts. Il faudra le réinstaller pour utiliser l\'assistant.'**
  String get aiDeleteBody;

  /// No description provided for @aiDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get aiDeleteConfirm;

  /// No description provided for @settingsAiSection.
  ///
  /// In fr, this message translates to:
  /// **'Assistant IA'**
  String get settingsAiSection;

  /// No description provided for @settingsAiModel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle Gemma 4'**
  String get settingsAiModel;

  /// No description provided for @settingsAiModelHint.
  ///
  /// In fr, this message translates to:
  /// **'Sur l\'appareil, hors connexion · 2,5 Go'**
  String get settingsAiModelHint;

  /// No description provided for @settingsVoice.
  ///
  /// In fr, this message translates to:
  /// **'Reconnaissance vocale'**
  String get settingsVoice;

  /// No description provided for @settingsVoiceHint.
  ///
  /// In fr, this message translates to:
  /// **'Moteur hors ligne distinct · français'**
  String get settingsVoiceHint;

  /// No description provided for @settingsVoiceReady.
  ///
  /// In fr, this message translates to:
  /// **'Prête'**
  String get settingsVoiceReady;

  /// No description provided for @qeAnalyseHeading.
  ///
  /// In fr, this message translates to:
  /// **'Analyse'**
  String get qeAnalyseHeading;

  /// No description provided for @qeStepVoice.
  ///
  /// In fr, this message translates to:
  /// **'Transcription terminée sur ton téléphone'**
  String get qeStepVoice;

  /// No description provided for @qeStepText.
  ///
  /// In fr, this message translates to:
  /// **'Texte reçu'**
  String get qeStepText;

  /// No description provided for @qeStepGemma.
  ///
  /// In fr, this message translates to:
  /// **'Gemma 4 repère les montants, catégories et comptes…'**
  String get qeStepGemma;

  /// No description provided for @qeSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get qeSkip;

  /// No description provided for @qeAiUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Assistant IA indisponible.'**
  String get qeAiUnavailable;

  /// No description provided for @qeManageAi.
  ///
  /// In fr, this message translates to:
  /// **'Gérer le modèle IA'**
  String get qeManageAi;

  /// No description provided for @asTitle.
  ///
  /// In fr, this message translates to:
  /// **'Copilote'**
  String get asTitle;

  /// No description provided for @asSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Sur ton téléphone · fonctionne hors connexion'**
  String get asSubtitle;

  /// No description provided for @asFootnote.
  ///
  /// In fr, this message translates to:
  /// **'Chiffres calculés par l\'application · expliqués par Gemma 4'**
  String get asFootnote;

  /// No description provided for @asTyping.
  ///
  /// In fr, this message translates to:
  /// **'Analyse de tes opérations…'**
  String get asTyping;

  /// No description provided for @asInputHint.
  ///
  /// In fr, this message translates to:
  /// **'Pose ta question…'**
  String get asInputHint;

  /// No description provided for @asSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get asSend;

  /// No description provided for @asIntro.
  ///
  /// In fr, this message translates to:
  /// **'Pose une question sur tes dépenses, tes budgets, tes soldes ou un achat. Les chiffres sont toujours calculés par l\'application.'**
  String get asIntro;

  /// No description provided for @asSuggest2.
  ///
  /// In fr, this message translates to:
  /// **'Quelle catégorie me coûte le plus ?'**
  String get asSuggest2;

  /// No description provided for @asSuggest3.
  ///
  /// In fr, this message translates to:
  /// **'Combien puis-je dépenser cette semaine ?'**
  String get asSuggest3;

  /// No description provided for @asSuggest5.
  ///
  /// In fr, this message translates to:
  /// **'Puis-je acheter un téléphone à 150 000 ?'**
  String get asSuggest5;

  /// No description provided for @asFallback.
  ///
  /// In fr, this message translates to:
  /// **'Je n\'ai pas bien compris. Tu peux me demander « Mes dépenses cette semaine » ou « Combien puis-je dépenser cette semaine ? ».'**
  String get asFallback;

  /// No description provided for @asError.
  ///
  /// In fr, this message translates to:
  /// **'Je n\'ai pas pu répondre. Réessaie.'**
  String get asError;

  /// No description provided for @asOffTitle.
  ///
  /// In fr, this message translates to:
  /// **'L\'assistant n\'est pas chargé'**
  String get asOffTitle;

  /// No description provided for @asOffBody.
  ///
  /// In fr, this message translates to:
  /// **'Les questions en langage naturel sont indisponibles pour l\'instant. Tous tes chiffres restent accessibles.'**
  String get asOffBody;

  /// No description provided for @asOffNotInstalled.
  ///
  /// In fr, this message translates to:
  /// **'L\'assistant n\'est pas installé. Tous tes chiffres restent accessibles.'**
  String get asOffNotInstalled;

  /// No description provided for @asOffUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'L\'assistant IA n\'est pas disponible sur ce téléphone. Tous tes chiffres restent accessibles.'**
  String get asOffUnavailable;

  /// No description provided for @asOffDownloading.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement de l\'assistant en cours. Tous tes chiffres restent accessibles.'**
  String get asOffDownloading;

  /// No description provided for @asLoad.
  ///
  /// In fr, this message translates to:
  /// **'Charger l\'assistant'**
  String get asLoad;

  /// No description provided for @asInstall.
  ///
  /// In fr, this message translates to:
  /// **'Installer l\'assistant'**
  String get asInstall;

  /// No description provided for @asLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de l\'assistant…'**
  String get asLoading;

  /// No description provided for @asShortcutDictate.
  ///
  /// In fr, this message translates to:
  /// **'Dicter'**
  String get asShortcutDictate;

  /// No description provided for @asLinkTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Voir les opérations'**
  String get asLinkTransactions;

  /// No description provided for @asLinkBudgets.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes budgets'**
  String get asLinkBudgets;

  /// No description provided for @asLinkAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes comptes'**
  String get asLinkAccounts;

  /// No description provided for @asLinkForecast.
  ///
  /// In fr, this message translates to:
  /// **'Voir la prévision'**
  String get asLinkForecast;

  /// No description provided for @asLinkSimulation.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la simulation'**
  String get asLinkSimulation;

  /// No description provided for @asPeriodToday.
  ///
  /// In fr, this message translates to:
  /// **'aujourd\'hui'**
  String get asPeriodToday;

  /// No description provided for @asPeriodWeek.
  ///
  /// In fr, this message translates to:
  /// **'cette semaine'**
  String get asPeriodWeek;

  /// No description provided for @asPeriodMonth.
  ///
  /// In fr, this message translates to:
  /// **'ce mois-ci'**
  String get asPeriodMonth;

  /// No description provided for @asPeriodLastMonth.
  ///
  /// In fr, this message translates to:
  /// **'le mois dernier'**
  String get asPeriodLastMonth;

  /// No description provided for @asSpending.
  ///
  /// In fr, this message translates to:
  /// **'Tu as dépensé {amount} FCFA {period}.'**
  String asSpending(String amount, String period);

  /// No description provided for @asSpendingCategory.
  ///
  /// In fr, this message translates to:
  /// **'Tu as dépensé {amount} FCFA en {category} {period}.'**
  String asSpendingCategory(String amount, String category, String period);

  /// No description provided for @asSpendingTop.
  ///
  /// In fr, this message translates to:
  /// **'Ta plus grosse dépense : {category}, {amount} FCFA ({percent} %).'**
  String asSpendingTop(String category, String amount, String percent);

  /// No description provided for @asSpendingNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dépense enregistrée {period}.'**
  String asSpendingNone(String period);

  /// No description provided for @asNoBudget.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'as pas encore de budget. Crée-en un pour savoir combien tu peux dépenser.'**
  String get asNoBudget;

  /// No description provided for @asNoBudgetCategory.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'as pas de budget pour {category}.'**
  String asNoBudgetCategory(String category);

  /// No description provided for @asBudget.
  ///
  /// In fr, this message translates to:
  /// **'Pour rester dans tes budgets, tu peux dépenser environ {week} FCFA sur les 7 prochains jours, soit {perDay} FCFA par jour.'**
  String asBudget(String week, String perDay);

  /// No description provided for @asBudgetCategory.
  ///
  /// In fr, this message translates to:
  /// **'Budget {category} : il te reste {remaining} FCFA sur {limit} FCFA.'**
  String asBudgetCategory(String category, String remaining, String limit);

  /// No description provided for @asBudgetExceeded.
  ///
  /// In fr, this message translates to:
  /// **'Tes budgets sont dépassés de {amount} FCFA ce mois-ci.'**
  String asBudgetExceeded(String amount);

  /// No description provided for @asBudgetCategoryExceeded.
  ///
  /// In fr, this message translates to:
  /// **'Le budget {category} est dépassé de {amount} FCFA.'**
  String asBudgetCategoryExceeded(String category, String amount);

  /// No description provided for @asRowRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Reste du budget de {month}'**
  String asRowRemaining(String month);

  /// No description provided for @asRowDaysLeft.
  ///
  /// In fr, this message translates to:
  /// **'Jours restants'**
  String get asRowDaysLeft;

  /// No description provided for @asRowWeek.
  ///
  /// In fr, this message translates to:
  /// **'Possible sur 7 jours'**
  String get asRowWeek;

  /// No description provided for @asRowSpentOf.
  ///
  /// In fr, this message translates to:
  /// **'{spent} sur {limit} FCFA'**
  String asRowSpentOf(String spent, String limit);

  /// No description provided for @asBalance.
  ///
  /// In fr, this message translates to:
  /// **'Tu as {amount} FCFA sur tes comptes.'**
  String asBalance(String amount);

  /// No description provided for @asBalanceAccount.
  ///
  /// In fr, this message translates to:
  /// **'Tu as {amount} FCFA sur {account}.'**
  String asBalanceAccount(String amount, String account);

  /// No description provided for @asRowTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get asRowTotal;

  /// No description provided for @asForecast.
  ///
  /// In fr, this message translates to:
  /// **'Ton solde devrait être d\'environ {amount} FCFA le {date}. Fiabilité {level} : c\'est une estimation, pas une certitude.'**
  String asForecast(String amount, String date, String level);

  /// No description provided for @asForecastNegative.
  ///
  /// In fr, this message translates to:
  /// **'Attention : ton solde passerait sous zéro vers le {date}.'**
  String asForecastNegative(String date);

  /// No description provided for @asForecastTooEarly.
  ///
  /// In fr, this message translates to:
  /// **'Les prévisions apparaîtront après environ deux semaines d\'opérations.'**
  String get asForecastTooEarly;

  /// No description provided for @asRowForecastOn.
  ///
  /// In fr, this message translates to:
  /// **'Solde prévu le {date}'**
  String asRowForecastOn(String date);

  /// No description provided for @asRowRange.
  ///
  /// In fr, this message translates to:
  /// **'Fourchette probable'**
  String get asRowRange;

  /// No description provided for @asRowRangeValue.
  ///
  /// In fr, this message translates to:
  /// **'{low} à {high} FCFA'**
  String asRowRangeValue(String low, String high);

  /// No description provided for @asRowReliability.
  ///
  /// In fr, this message translates to:
  /// **'Fiabilité'**
  String get asRowReliability;

  /// No description provided for @asSimPossible.
  ///
  /// In fr, this message translates to:
  /// **'C\'est possible : ton disponible le plus bas serait d\'environ {lowest} FCFA, le {date}.'**
  String asSimPossible(String lowest, String date);

  /// No description provided for @asSimTight.
  ///
  /// In fr, this message translates to:
  /// **'C\'est possible, mais serré : ton disponible descendrait à environ {lowest} FCFA le {date}.'**
  String asSimTight(String lowest, String date);

  /// No description provided for @asSimDiscouraged.
  ///
  /// In fr, this message translates to:
  /// **'Pas maintenant : ton disponible passerait sous zéro vers le {date}.'**
  String asSimDiscouraged(String date);

  /// No description provided for @asRowLowest.
  ///
  /// In fr, this message translates to:
  /// **'Disponible le plus bas'**
  String get asRowLowest;

  /// No description provided for @asRowEndWith.
  ///
  /// In fr, this message translates to:
  /// **'Le {date}, avec l\'achat'**
  String asRowEndWith(String date);

  /// No description provided for @asRowEndWithout.
  ///
  /// In fr, this message translates to:
  /// **'Le {date}, sans l\'achat'**
  String asRowEndWithout(String date);

  /// No description provided for @asSuggestSave.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi j\'ai du mal à économiser ?'**
  String get asSuggestSave;

  /// No description provided for @asSuggestGoal.
  ///
  /// In fr, this message translates to:
  /// **'Comment économiser 100 000 en 3 mois ?'**
  String get asSuggestGoal;

  /// No description provided for @asPrepared.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai préparé cette opération. Vérifie avant d\'enregistrer :'**
  String get asPrepared;

  /// No description provided for @asPreparedMany.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai préparé ces {count} opérations. Vérifie avant d\'enregistrer :'**
  String asPreparedMany(int count);

  /// No description provided for @asPreparedNone.
  ///
  /// In fr, this message translates to:
  /// **'Je n\'ai pas trouvé de montant. Écris par exemple « Taxi 2 500 avec Wave ».'**
  String get asPreparedNone;

  /// No description provided for @asSavePrepared.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Enregistrer} other{Enregistrer les {count} opérations}}'**
  String asSavePrepared(int count);

  /// No description provided for @asEditPrepared.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get asEditPrepared;

  /// No description provided for @asSavedOne.
  ///
  /// In fr, this message translates to:
  /// **'{kind} enregistrée · solde {account} : {balance} FCFA'**
  String asSavedOne(String kind, String account, String balance);

  /// No description provided for @asSavedMany.
  ///
  /// In fr, this message translates to:
  /// **'{count} opérations enregistrées'**
  String asSavedMany(int count);

  /// No description provided for @asSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'L\'enregistrement a échoué. Touche « Modifier » pour vérifier l\'opération.'**
  String get asSaveFailed;

  /// No description provided for @asNotSaved.
  ///
  /// In fr, this message translates to:
  /// **'Non enregistrée'**
  String get asNotSaved;

  /// No description provided for @asRowAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get asRowAmount;

  /// No description provided for @asRowCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get asRowCategory;

  /// No description provided for @asRowAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get asRowAccount;

  /// No description provided for @asRowDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get asRowDate;

  /// No description provided for @asSavingsTooEarly.
  ///
  /// In fr, this message translates to:
  /// **'Il faut environ un mois d\'opérations pour faire ce bilan.'**
  String get asSavingsTooEarly;

  /// No description provided for @asSavings.
  ///
  /// In fr, this message translates to:
  /// **'En moyenne, tu gagnes {income} FCFA et tu dépenses {expenses} FCFA par mois. Tes charges fixes en représentent {percent} %.'**
  String asSavings(String income, String expenses, String percent);

  /// No description provided for @asSavingsDeficit.
  ///
  /// In fr, this message translates to:
  /// **'En moyenne, tes dépenses ({expenses} FCFA) dépassent tes revenus ({income} FCFA) chaque mois. Tes charges fixes en représentent {percent} %.'**
  String asSavingsDeficit(String expenses, String income, String percent);

  /// No description provided for @asRowIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenus moyens'**
  String get asRowIncome;

  /// No description provided for @asRowExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses moyennes'**
  String get asRowExpenses;

  /// No description provided for @asRowFixed.
  ///
  /// In fr, this message translates to:
  /// **'Dont charges fixes'**
  String get asRowFixed;

  /// No description provided for @asGoalFeasible.
  ///
  /// In fr, this message translates to:
  /// **'C\'est faisable : il faut mettre de côté environ {monthly} FCFA par mois, et tu épargnes en moyenne {surplus} FCFA par mois.'**
  String asGoalFeasible(String monthly, String surplus);

  /// No description provided for @asGoalHard.
  ///
  /// In fr, this message translates to:
  /// **'Il faudrait mettre de côté {monthly} FCFA par mois, plus que ton épargne moyenne actuelle ({surplus} FCFA). Un délai plus long ou moins de dépenses aideraient.'**
  String asGoalHard(String monthly, String surplus);

  /// No description provided for @asGoalUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Il faut mettre de côté environ {monthly} FCFA par mois.'**
  String asGoalUnknown(String monthly);

  /// No description provided for @asRowMonthly.
  ///
  /// In fr, this message translates to:
  /// **'À mettre de côté par mois'**
  String get asRowMonthly;

  /// No description provided for @asRowSurplus.
  ///
  /// In fr, this message translates to:
  /// **'Ton épargne moyenne actuelle'**
  String get asRowSurplus;

  /// No description provided for @asRowDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get asRowDeadline;

  /// No description provided for @asLinkGoal.
  ///
  /// In fr, this message translates to:
  /// **'Créer l\'objectif'**
  String get asLinkGoal;

  /// No description provided for @simAskCopilot.
  ///
  /// In fr, this message translates to:
  /// **'En parler au Copilote'**
  String get simAskCopilot;

  /// No description provided for @simAskQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Puis-je acheter {label} à {price} FCFA ?'**
  String simAskQuestion(String label, String price);

  /// No description provided for @simAskQuestionNoLabel.
  ///
  /// In fr, this message translates to:
  /// **'Puis-je faire un achat de {price} FCFA ?'**
  String simAskQuestionNoLabel(String price);

  /// No description provided for @goalDueMonths.
  ///
  /// In fr, this message translates to:
  /// **'{count} mois'**
  String goalDueMonths(int count);

  /// No description provided for @settingsClearHistory.
  ///
  /// In fr, this message translates to:
  /// **'Effacer l\'historique de conversation'**
  String get settingsClearHistory;

  /// No description provided for @settingsClearHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Effacer l\'historique ?'**
  String get settingsClearHistoryTitle;

  /// No description provided for @settingsClearHistoryBody.
  ///
  /// In fr, this message translates to:
  /// **'Toutes tes conversations avec le Copilote seront supprimées. Tes opérations, budgets et objectifs ne changent pas.'**
  String get settingsClearHistoryBody;

  /// No description provided for @settingsClearHistoryConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get settingsClearHistoryConfirm;

  /// No description provided for @settingsHistoryCleared.
  ///
  /// In fr, this message translates to:
  /// **'Historique effacé.'**
  String get settingsHistoryCleared;

  /// No description provided for @ntChannelReminders.
  ///
  /// In fr, this message translates to:
  /// **'Rappels d\'échéance'**
  String get ntChannelReminders;

  /// No description provided for @ntChannelRemindersHint.
  ///
  /// In fr, this message translates to:
  /// **'Le jour d\'une opération récurrente, à 9 h'**
  String get ntChannelRemindersHint;

  /// No description provided for @ntChannelBudgets.
  ///
  /// In fr, this message translates to:
  /// **'Alertes de budget'**
  String get ntChannelBudgets;

  /// No description provided for @ntChannelBudgetsHint.
  ///
  /// In fr, this message translates to:
  /// **'Au seuil d\'alerte et au dépassement'**
  String get ntChannelBudgetsHint;

  /// No description provided for @ntChannelLowBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde bas'**
  String get ntChannelLowBalance;

  /// No description provided for @ntChannelLowBalanceHint.
  ///
  /// In fr, this message translates to:
  /// **'3 jours avant un solde bas possible'**
  String get ntChannelLowBalanceHint;

  /// No description provided for @ntReminderTitle.
  ///
  /// In fr, this message translates to:
  /// **'{name} · {amount} FCFA aujourd\'hui'**
  String ntReminderTitle(String name, String amount);

  /// No description provided for @ntReminderConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Touche pour l\'enregistrer.'**
  String get ntReminderConfirm;

  /// No description provided for @ntReminderAuto.
  ///
  /// In fr, this message translates to:
  /// **'Elle sera enregistrée à l\'ouverture de l\'application.'**
  String get ntReminderAuto;

  /// No description provided for @ntBudgetWarningTitle.
  ///
  /// In fr, this message translates to:
  /// **'{category} : {percent} % du budget utilisé'**
  String ntBudgetWarningTitle(String category, String percent);

  /// No description provided for @ntBudgetWarningBody.
  ///
  /// In fr, this message translates to:
  /// **'Il te reste {remaining} FCFA jusqu\'à la fin du mois.'**
  String ntBudgetWarningBody(String remaining);

  /// No description provided for @ntBudgetReachedTitle.
  ///
  /// In fr, this message translates to:
  /// **'{category} : budget atteint'**
  String ntBudgetReachedTitle(String category);

  /// No description provided for @ntBudgetExceededTitle.
  ///
  /// In fr, this message translates to:
  /// **'{category} : budget dépassé de {amount} FCFA'**
  String ntBudgetExceededTitle(String category, String amount);

  /// No description provided for @ntBudgetBody.
  ///
  /// In fr, this message translates to:
  /// **'Touche pour voir tes budgets.'**
  String get ntBudgetBody;

  /// No description provided for @ntLowBalanceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Solde bas possible le {date}'**
  String ntLowBalanceTitle(String date);

  /// No description provided for @ntLowBalanceBody.
  ///
  /// In fr, this message translates to:
  /// **'≈ {amount} FCFA prévus. C\'est une estimation : touche pour voir la prévision.'**
  String ntLowBalanceBody(String amount);

  /// No description provided for @settingsNotifSection.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get settingsNotifSection;

  /// No description provided for @dashboardShowAmounts.
  ///
  /// In fr, this message translates to:
  /// **'Afficher les montants'**
  String get dashboardShowAmounts;

  /// No description provided for @dashboardHideAmounts.
  ///
  /// In fr, this message translates to:
  /// **'Masquer les montants'**
  String get dashboardHideAmounts;

  /// No description provided for @settingsLocalOnly.
  ///
  /// In fr, this message translates to:
  /// **'Données stockées uniquement sur ce téléphone'**
  String get settingsLocalOnly;

  /// No description provided for @settingsPrefsSection.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get settingsPrefsSection;

  /// No description provided for @settingsCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Devise'**
  String get settingsCurrency;

  /// No description provided for @settingsCurrencyValue.
  ///
  /// In fr, this message translates to:
  /// **'FCFA (XOF)'**
  String get settingsCurrencyValue;

  /// No description provided for @settingsLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageValue.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get settingsLanguageValue;

  /// No description provided for @settingsTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get settingsThemeDark;

  /// No description provided for @settingsRecurring.
  ///
  /// In fr, this message translates to:
  /// **'Opérations récurrentes'**
  String get settingsRecurring;

  /// No description provided for @settingsRecurringCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune active} =1{1 active} other{{count} actives}}'**
  String settingsRecurringCount(int count);

  /// No description provided for @settingsHideAmounts.
  ///
  /// In fr, this message translates to:
  /// **'Masquer les montants à l\'ouverture'**
  String get settingsHideAmounts;

  /// No description provided for @settingsHideAmountsHint.
  ///
  /// In fr, this message translates to:
  /// **'Sur l\'accueil, touche l\'œil pour les afficher'**
  String get settingsHideAmountsHint;

  /// No description provided for @settingsSecuritySection.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité et confidentialité'**
  String get settingsSecuritySection;

  /// No description provided for @settingsPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyHint.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée n\'est envoyée sur Internet, sauf le téléchargement du modèle IA si tu l\'installes.'**
  String get settingsPrivacyHint;

  /// No description provided for @settingsFooter.
  ///
  /// In fr, this message translates to:
  /// **'{app} {version} · données stockées localement'**
  String settingsFooter(String app, String version);

  /// No description provided for @lockEnter.
  ///
  /// In fr, this message translates to:
  /// **'Saisis ton code'**
  String get lockEnter;

  /// No description provided for @lockWrong.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Code incorrect. Encore 1 essai.} other{Code incorrect. Encore {count} essais.}}'**
  String lockWrong(int count);

  /// No description provided for @lockWait.
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'essais. Réessaie dans {time}.'**
  String lockWait(String time);

  /// No description provided for @lockBiometricReason.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller Finao'**
  String get lockBiometricReason;

  /// No description provided for @lockBiometricButton.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte ou visage'**
  String get lockBiometricButton;

  /// No description provided for @lockDelete.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get lockDelete;

  /// No description provided for @lockForgot.
  ///
  /// In fr, this message translates to:
  /// **'Code oublié ?'**
  String get lockForgot;

  /// No description provided for @lockForgotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code oublié'**
  String get lockForgotTitle;

  /// No description provided for @lockForgotBody.
  ///
  /// In fr, this message translates to:
  /// **'Sans serveur, le code ne peut pas être récupéré. Si tu as activé l\'empreinte ou le visage, utilise-les. Sinon, la seule solution est d\'effacer les données de l\'application dans les réglages d\'Android : toutes tes opérations seront perdues.'**
  String get lockForgotBody;

  /// No description provided for @lockForgotOk.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get lockForgotOk;

  /// No description provided for @pinCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un code'**
  String get pinCreateTitle;

  /// No description provided for @pinCreateHint.
  ///
  /// In fr, this message translates to:
  /// **'4 chiffres, demandés à l\'ouverture de l\'application.'**
  String get pinCreateHint;

  /// No description provided for @pinCreateWarning.
  ///
  /// In fr, this message translates to:
  /// **'Retiens-le bien : sans serveur, un code oublié ne peut pas être récupéré. Active aussi l\'empreinte ou le visage si ton téléphone le permet.'**
  String get pinCreateWarning;

  /// No description provided for @pinConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirme ton code'**
  String get pinConfirmTitle;

  /// No description provided for @pinMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux codes ne correspondent pas. Recommence.'**
  String get pinMismatch;

  /// No description provided for @pinCurrentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code actuel'**
  String get pinCurrentTitle;

  /// No description provided for @pinNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code'**
  String get pinNewTitle;

  /// No description provided for @pinChanged.
  ///
  /// In fr, this message translates to:
  /// **'Code modifié.'**
  String get pinChanged;

  /// No description provided for @pinEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillage activé.'**
  String get pinEnabled;

  /// No description provided for @pinDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillage désactivé.'**
  String get pinDisabled;

  /// No description provided for @settingsLock.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillage de l\'application'**
  String get settingsLock;

  /// No description provided for @settingsLockHint.
  ///
  /// In fr, this message translates to:
  /// **'Demandé à chaque ouverture'**
  String get settingsLockHint;

  /// No description provided for @settingsPin.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN'**
  String get settingsPin;

  /// No description provided for @settingsPinChange.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get settingsPinChange;

  /// No description provided for @settingsBiometric.
  ///
  /// In fr, this message translates to:
  /// **'Biométrie (facultatif)'**
  String get settingsBiometric;

  /// No description provided for @settingsBiometricHint.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte ou visage à la place du code'**
  String get settingsBiometricHint;

  /// No description provided for @settingsBiometricFailed.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte ou visage non reconnu.'**
  String get settingsBiometricFailed;

  /// No description provided for @settingsLockDelay.
  ///
  /// In fr, this message translates to:
  /// **'Verrouiller après'**
  String get settingsLockDelay;

  /// No description provided for @lockDelayImmediately.
  ///
  /// In fr, this message translates to:
  /// **'Immédiatement'**
  String get lockDelayImmediately;

  /// No description provided for @lockDelayOneMinute.
  ///
  /// In fr, this message translates to:
  /// **'1 minute'**
  String get lockDelayOneMinute;

  /// No description provided for @lockDelayFiveMinutes.
  ///
  /// In fr, this message translates to:
  /// **'5 minutes'**
  String get lockDelayFiveMinutes;

  /// No description provided for @bkSection.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde et données'**
  String get bkSection;

  /// No description provided for @bkBackup.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde'**
  String get bkBackup;

  /// No description provided for @bkNever.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sauvegarde pour l\'instant'**
  String get bkNever;

  /// No description provided for @bkLast.
  ///
  /// In fr, this message translates to:
  /// **'{day} à {time} · {size}, chiffrée'**
  String bkLast(String day, String time, String size);

  /// No description provided for @bkSaving.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde en cours…'**
  String get bkSaving;

  /// No description provided for @bkRestoring.
  ///
  /// In fr, this message translates to:
  /// **'Restauration en cours…'**
  String get bkRestoring;

  /// No description provided for @bkFailedStorage.
  ///
  /// In fr, this message translates to:
  /// **'La sauvegarde a échoué. Espace de stockage insuffisant. Libère de l\'espace puis réessaie.'**
  String get bkFailedStorage;

  /// No description provided for @bkFailedOther.
  ///
  /// In fr, this message translates to:
  /// **'La sauvegarde a échoué. Réessaie.'**
  String get bkFailedOther;

  /// No description provided for @bkRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get bkRetry;

  /// No description provided for @bkDone.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde terminée.'**
  String get bkDone;

  /// No description provided for @bkRestore.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer une sauvegarde'**
  String get bkRestore;

  /// No description provided for @bkRestoreHint.
  ///
  /// In fr, this message translates to:
  /// **'Fichier .finao et son mot de passe'**
  String get bkRestoreHint;

  /// No description provided for @bkDrive.
  ///
  /// In fr, this message translates to:
  /// **'Google Drive'**
  String get bkDrive;

  /// No description provided for @bkDriveHint.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde, restauration et synchronisation chiffrées. Facultatif.'**
  String get bkDriveHint;

  /// No description provided for @bkComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get bkComingSoon;

  /// No description provided for @bkPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe de la sauvegarde'**
  String get bkPasswordTitle;

  /// No description provided for @bkPasswordWarning.
  ///
  /// In fr, this message translates to:
  /// **'Il protège le fichier. Sans lui, la sauvegarde ne pourra pas être restaurée : il ne peut pas être récupéré.'**
  String get bkPasswordWarning;

  /// No description provided for @bkPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get bkPassword;

  /// No description provided for @bkPasswordConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirme le mot de passe'**
  String get bkPasswordConfirm;

  /// No description provided for @bkPasswordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 8 caractères.'**
  String get bkPasswordTooShort;

  /// No description provided for @bkPasswordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux mots de passe ne correspondent pas.'**
  String get bkPasswordMismatch;

  /// No description provided for @bkPasswordShow.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get bkPasswordShow;

  /// No description provided for @bkSave.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder'**
  String get bkSave;

  /// No description provided for @bkContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get bkContinue;

  /// No description provided for @bkCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get bkCancel;

  /// No description provided for @bkUnreadable.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe incorrect, ou ce fichier n\'est pas une sauvegarde.'**
  String get bkUnreadable;

  /// No description provided for @bkTooNew.
  ///
  /// In fr, this message translates to:
  /// **'Cette sauvegarde vient d\'une version plus récente de l\'application. Mets l\'application à jour puis réessaie.'**
  String get bkTooNew;

  /// No description provided for @bkConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer la sauvegarde du {day} ?'**
  String bkConfirmTitle(String day);

  /// No description provided for @bkConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Tes données actuelles seront remplacées par celles du {day} à {time}. Les opérations saisies depuis seront perdues.'**
  String bkConfirmBody(String day, String time);

  /// No description provided for @bkConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer'**
  String get bkConfirm;

  /// No description provided for @bkRestored.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde restaurée.'**
  String get bkRestored;

  /// No description provided for @bkRestoreFailed.
  ///
  /// In fr, this message translates to:
  /// **'La restauration a échoué. Tes données actuelles n\'ont pas changé.'**
  String get bkRestoreFailed;

  /// No description provided for @exExport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter mes données'**
  String get exExport;

  /// No description provided for @exExportHint.
  ///
  /// In fr, this message translates to:
  /// **'CSV, PDF'**
  String get exExportHint;

  /// No description provided for @exTitle.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get exTitle;

  /// No description provided for @exWarning.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier exporté n\'est pas chiffré : toute personne qui l\'ouvre voit tes opérations. Partage-le avec prudence.'**
  String get exWarning;

  /// No description provided for @exCsv.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les opérations (CSV)'**
  String get exCsv;

  /// No description provided for @exCsvHint.
  ///
  /// In fr, this message translates to:
  /// **'Pour Excel ou Google Sheets'**
  String get exCsvHint;

  /// No description provided for @exPdf.
  ///
  /// In fr, this message translates to:
  /// **'Relevé du mois (PDF)'**
  String get exPdf;

  /// No description provided for @exPdfHint.
  ///
  /// In fr, this message translates to:
  /// **'Totaux, répartition et opérations'**
  String get exPdfHint;

  /// No description provided for @exMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get exMonth;

  /// No description provided for @exShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get exShare;

  /// No description provided for @exSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get exSave;

  /// No description provided for @exSaved.
  ///
  /// In fr, this message translates to:
  /// **'Fichier enregistré.'**
  String get exSaved;

  /// No description provided for @exFailed.
  ///
  /// In fr, this message translates to:
  /// **'L\'export a échoué. Réessaie.'**
  String get exFailed;

  /// No description provided for @exEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération à exporter.'**
  String get exEmpty;

  /// No description provided for @exCsvDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get exCsvDate;

  /// No description provided for @exCsvKind.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get exCsvKind;

  /// No description provided for @exCsvAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant (FCFA)'**
  String get exCsvAmount;

  /// No description provided for @exCsvCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get exCsvCategory;

  /// No description provided for @exCsvSubcategory.
  ///
  /// In fr, this message translates to:
  /// **'Sous-catégorie'**
  String get exCsvSubcategory;

  /// No description provided for @exCsvAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get exCsvAccount;

  /// No description provided for @exCsvToAccount.
  ///
  /// In fr, this message translates to:
  /// **'Vers le compte'**
  String get exCsvToAccount;

  /// No description provided for @exCsvDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get exCsvDescription;

  /// No description provided for @exCsvEntry.
  ///
  /// In fr, this message translates to:
  /// **'Saisie'**
  String get exCsvEntry;

  /// No description provided for @exPdfTitle.
  ///
  /// In fr, this message translates to:
  /// **'Relevé de {month}'**
  String exPdfTitle(String month);

  /// No description provided for @exPdfGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Généré le {date} · données de ce téléphone'**
  String exPdfGenerated(String date);

  /// No description provided for @exPdfIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get exPdfIncome;

  /// No description provided for @exPdfExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get exPdfExpenses;

  /// No description provided for @exPdfNet.
  ///
  /// In fr, this message translates to:
  /// **'Solde du mois'**
  String get exPdfNet;

  /// No description provided for @exPdfBreakdown.
  ///
  /// In fr, this message translates to:
  /// **'Répartition des dépenses'**
  String get exPdfBreakdown;

  /// No description provided for @exPdfOperations.
  ///
  /// In fr, this message translates to:
  /// **'Opérations ({count})'**
  String exPdfOperations(int count);

  /// No description provided for @exPdfTransfersNote.
  ///
  /// In fr, this message translates to:
  /// **'Transferts entre tes comptes exclus des totaux.'**
  String get exPdfTransfersNote;

  /// No description provided for @exPdfOthers.
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get exPdfOthers;

  /// No description provided for @ntChannelBackup.
  ///
  /// In fr, this message translates to:
  /// **'Rappel de sauvegarde'**
  String get ntChannelBackup;

  /// No description provided for @ntChannelBackupHint.
  ///
  /// In fr, this message translates to:
  /// **'Un mois après la dernière sauvegarde'**
  String get ntChannelBackupHint;

  /// No description provided for @ntBackupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pense à sauvegarder tes données'**
  String get ntBackupTitle;

  /// No description provided for @ntBackupBodyLast.
  ///
  /// In fr, this message translates to:
  /// **'Ta dernière sauvegarde date du {date}.'**
  String ntBackupBodyLast(String date);

  /// No description provided for @ntBackupBodyNever.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'as encore jamais sauvegardé tes opérations.'**
  String get ntBackupBodyNever;

  /// No description provided for @settingsMonthStart.
  ///
  /// In fr, this message translates to:
  /// **'Début du mois budgétaire'**
  String get settingsMonthStart;

  /// No description provided for @settingsMonthStartHint.
  ///
  /// In fr, this message translates to:
  /// **'Budgets et totaux du mois'**
  String get settingsMonthStartHint;

  /// No description provided for @settingsMonthStartFirst.
  ///
  /// In fr, this message translates to:
  /// **'Le 1er'**
  String get settingsMonthStartFirst;

  /// No description provided for @settingsMonthStartDay.
  ///
  /// In fr, this message translates to:
  /// **'Le {day}'**
  String settingsMonthStartDay(int day);

  /// No description provided for @settingsMonthStartExplain.
  ///
  /// In fr, this message translates to:
  /// **'Par exemple le 25 si ton salaire arrive le 25 : ton mois va alors du 25 au 24 du mois suivant. Les prévisions, échéances et objectifs gardent leurs dates.'**
  String get settingsMonthStartExplain;

  /// No description provided for @inBudgetExceeded.
  ///
  /// In fr, this message translates to:
  /// **'Ton budget {category} est dépassé de {amount} FCFA.'**
  String inBudgetExceeded(String category, String amount);

  /// No description provided for @inBudgetExceededDriver.
  ///
  /// In fr, this message translates to:
  /// **'Ton budget {category} est dépassé de {amount} FCFA, surtout à cause de {driver} ({count} opérations).'**
  String inBudgetExceededDriver(
    String category,
    String amount,
    String driver,
    String count,
  );

  /// No description provided for @inBudgetExceededGlobal.
  ///
  /// In fr, this message translates to:
  /// **'Ton budget du mois est dépassé de {amount} FCFA.'**
  String inBudgetExceededGlobal(String amount);

  /// No description provided for @inBudgetWarning.
  ///
  /// In fr, this message translates to:
  /// **'Ton budget {category} est utilisé à {percent} % : il te reste {remaining} FCFA pour {days} jours.'**
  String inBudgetWarning(
    String category,
    String percent,
    String remaining,
    String days,
  );

  /// No description provided for @inBudgetWarningGlobal.
  ///
  /// In fr, this message translates to:
  /// **'Ton budget du mois est utilisé à {percent} % : il te reste {remaining} FCFA pour {days} jours.'**
  String inBudgetWarningGlobal(String percent, String remaining, String days);

  /// No description provided for @inLowBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde bas possible le {date} (≈ {amount} FCFA).'**
  String inLowBalance(String date, String amount);

  /// No description provided for @inLowBalanceBeforeIncome.
  ///
  /// In fr, this message translates to:
  /// **'Solde bas possible le {date} (≈ {amount} FCFA), juste avant ton salaire.'**
  String inLowBalanceBeforeIncome(String date, String amount);

  /// No description provided for @inPending.
  ///
  /// In fr, this message translates to:
  /// **'{name} ({amount} FCFA) attend ta confirmation.'**
  String inPending(String name, String amount);

  /// No description provided for @inSpendingUp.
  ///
  /// In fr, this message translates to:
  /// **'Tu as dépensé {percent} % de plus que le mois dernier à la même date : {current} FCFA contre {previous} FCFA.'**
  String inSpendingUp(String percent, String current, String previous);

  /// No description provided for @inAskBudget.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi mon budget {category} est dépassé ?'**
  String inAskBudget(String category);

  /// No description provided for @inAskBudgetGlobal.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi mon budget du mois est dépassé ?'**
  String get inAskBudgetGlobal;

  /// No description provided for @inAskSpend.
  ///
  /// In fr, this message translates to:
  /// **'Combien puis-je dépenser cette semaine ?'**
  String get inAskSpend;

  /// No description provided for @inAskForecast.
  ///
  /// In fr, this message translates to:
  /// **'Mon solde à la fin du mois ?'**
  String get inAskForecast;

  /// No description provided for @inAskSpendingUp.
  ///
  /// In fr, this message translates to:
  /// **'Quelle catégorie me coûte le plus ?'**
  String get inAskSpendingUp;

  /// No description provided for @inAskCopilot.
  ///
  /// In fr, this message translates to:
  /// **'Demander au Copilote'**
  String get inAskCopilot;

  /// No description provided for @inSeePending.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'échéance'**
  String get inSeePending;

  /// No description provided for @homeForecastTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dans 30 jours'**
  String get homeForecastTitle;

  /// No description provided for @homeForecastRange.
  ///
  /// In fr, this message translates to:
  /// **'Probablement entre {low} et {high} FCFA'**
  String homeForecastRange(String low, String high);

  /// No description provided for @homeForecastLink.
  ///
  /// In fr, this message translates to:
  /// **'Comprendre cette prévision'**
  String get homeForecastLink;

  /// No description provided for @settingsSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions du Copilote'**
  String get settingsSuggestions;

  /// No description provided for @settingsSuggestionsHint.
  ///
  /// In fr, this message translates to:
  /// **'Phrases factuelles sur l\'accueil'**
  String get settingsSuggestionsHint;

  /// No description provided for @txDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer'**
  String get txDuplicate;

  /// No description provided for @simTitle.
  ///
  /// In fr, this message translates to:
  /// **'Simuler un achat'**
  String get simTitle;

  /// No description provided for @simWhat.
  ///
  /// In fr, this message translates to:
  /// **'Achat envisagé'**
  String get simWhat;

  /// No description provided for @simWhatHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : Téléphone'**
  String get simWhatHint;

  /// No description provided for @simPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get simPrice;

  /// No description provided for @simWhen.
  ///
  /// In fr, this message translates to:
  /// **'Quand ?'**
  String get simWhen;

  /// No description provided for @simToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get simToday;

  /// No description provided for @simAfterIncome.
  ///
  /// In fr, this message translates to:
  /// **'Après « {name} » ({date})'**
  String simAfterIncome(String name, String date);

  /// No description provided for @simUseSavings.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser mon épargne « {name} »'**
  String simUseSavings(String name);

  /// No description provided for @simSavingsHelp.
  ///
  /// In fr, this message translates to:
  /// **'{amount} FCFA déjà mis de côté'**
  String simSavingsHelp(String amount);

  /// No description provided for @simPossible.
  ///
  /// In fr, this message translates to:
  /// **'Possible'**
  String get simPossible;

  /// No description provided for @simTight.
  ///
  /// In fr, this message translates to:
  /// **'Possible, mais serré'**
  String get simTight;

  /// No description provided for @simDiscouraged.
  ///
  /// In fr, this message translates to:
  /// **'Déconseillé'**
  String get simDiscouraged;

  /// No description provided for @simExplainOk.
  ///
  /// In fr, this message translates to:
  /// **'Ton solde disponible resterait au-dessus de {amount} FCFA jusqu\'au {date}.'**
  String simExplainOk(String amount, String date);

  /// No description provided for @simExplainTight.
  ///
  /// In fr, this message translates to:
  /// **'Ton solde disponible resterait positif, mais descendrait à ≈ {amount} FCFA le {date}. Garde une marge pour les imprévus.'**
  String simExplainTight(String amount, String date);

  /// No description provided for @simExplainNeg.
  ///
  /// In fr, this message translates to:
  /// **'Si tu achètes {what} {when}, ton solde disponible passerait sous zéro à partir du {date}.'**
  String simExplainNeg(String what, String when, String date);

  /// No description provided for @simExplainNegAdvice.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ton épargne ou attendre réduirait le risque.'**
  String get simExplainNegAdvice;

  /// No description provided for @simThisPurchase.
  ///
  /// In fr, this message translates to:
  /// **'cet achat'**
  String get simThisPurchase;

  /// No description provided for @simTodayLower.
  ///
  /// In fr, this message translates to:
  /// **'aujourd\'hui'**
  String get simTodayLower;

  /// No description provided for @simOnDate.
  ///
  /// In fr, this message translates to:
  /// **'le {date}'**
  String simOnDate(String date);

  /// No description provided for @simLowest.
  ///
  /// In fr, this message translates to:
  /// **'Solde le plus bas'**
  String get simLowest;

  /// No description provided for @simLowestOn.
  ///
  /// In fr, this message translates to:
  /// **'le {date}'**
  String simLowestOn(String date);

  /// No description provided for @simBalanceOn.
  ///
  /// In fr, this message translates to:
  /// **'Solde au {date}'**
  String simBalanceOn(String date);

  /// No description provided for @simWithout.
  ///
  /// In fr, this message translates to:
  /// **'sans achat : ≈ {amount}'**
  String simWithout(String amount);

  /// No description provided for @simReliability.
  ///
  /// In fr, this message translates to:
  /// **'Fiabilité {level} · estimation basée sur {period}, pas une certitude.'**
  String simReliability(String level, String period);

  /// No description provided for @simPeriodDays.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{ton dernier jour} other{tes {count} derniers jours}}'**
  String simPeriodDays(int count);

  /// No description provided for @simPeriodMonths.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{ton dernier mois} other{tes {count} derniers mois}}'**
  String simPeriodMonths(int count);

  /// No description provided for @simCreateGoal.
  ///
  /// In fr, this message translates to:
  /// **'Créer un objectif pour cet achat'**
  String get simCreateGoal;

  /// No description provided for @simEnterPrice.
  ///
  /// In fr, this message translates to:
  /// **'Indique un prix pour voir le résultat.'**
  String get simEnterPrice;

  /// No description provided for @simAvailableNote.
  ///
  /// In fr, this message translates to:
  /// **'Calculé sur ton solde disponible : l\'argent réservé à tes objectifs est mis de côté.'**
  String get simAvailableNote;

  /// No description provided for @forecastSimulate.
  ///
  /// In fr, this message translates to:
  /// **'Simuler un achat'**
  String get forecastSimulate;

  /// No description provided for @forecastSimulateExample.
  ///
  /// In fr, this message translates to:
  /// **'« Puis-je acheter un téléphone à 150 000 FCFA ? »'**
  String get forecastSimulateExample;

  /// No description provided for @goalAdviceIncome.
  ///
  /// In fr, this message translates to:
  /// **'Pour tenir la date : verse {amount} FCFA le jour de « {name} » (le {day})'**
  String goalAdviceIncome(String amount, String name, String day);

  /// No description provided for @goalAdviceMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Pour tenir la date : verse {amount} FCFA chaque mois'**
  String goalAdviceMonthly(String amount);

  /// No description provided for @goalAdvicePostpone.
  ///
  /// In fr, this message translates to:
  /// **', ou repousse la date au {date} (≈ {amount} par mois)'**
  String goalAdvicePostpone(String date, String amount);

  /// No description provided for @goalPostponeButton.
  ///
  /// In fr, this message translates to:
  /// **'Repousser au {date}'**
  String goalPostponeButton(String date);

  /// No description provided for @goalPostponed.
  ///
  /// In fr, this message translates to:
  /// **'Date repoussée au {date}.'**
  String goalPostponed(String date);

  /// No description provided for @goalEmergencyAdvice.
  ///
  /// In fr, this message translates to:
  /// **'Objectif conseillé : 3 mois de dépenses (≈ {amount} FCFA).'**
  String goalEmergencyAdvice(String amount);

  /// No description provided for @goalEmergencyAdviceNoData.
  ///
  /// In fr, this message translates to:
  /// **'Objectif conseillé : 3 mois de dépenses.'**
  String get goalEmergencyAdviceNoData;

  /// No description provided for @goalEmergencySuggestion.
  ///
  /// In fr, this message translates to:
  /// **'3 mois de tes dépenses ≈ {amount} FCFA.'**
  String goalEmergencySuggestion(String amount);

  /// No description provided for @accountReserved.
  ///
  /// In fr, this message translates to:
  /// **'dont {amount} réservés'**
  String accountReserved(String amount);

  /// No description provided for @accountAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Disponible : {available} FCFA · {reserved} réservés aux objectifs'**
  String accountAvailable(String available, String reserved);

  /// No description provided for @forecastTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prévisions'**
  String get forecastTitle;

  /// No description provided for @forecastHorizon7.
  ///
  /// In fr, this message translates to:
  /// **'7 jours'**
  String get forecastHorizon7;

  /// No description provided for @forecastHorizon30.
  ///
  /// In fr, this message translates to:
  /// **'30 jours'**
  String get forecastHorizon30;

  /// No description provided for @forecastHorizon90.
  ///
  /// In fr, this message translates to:
  /// **'90 jours'**
  String get forecastHorizon90;

  /// No description provided for @forecastInsufficientTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore assez de données'**
  String get forecastInsufficientTitle;

  /// No description provided for @forecastInsufficientBody.
  ///
  /// In fr, this message translates to:
  /// **'Pour estimer ton solde à venir, l\'appli a besoin d\'environ deux semaines d\'opérations.'**
  String get forecastInsufficientBody;

  /// No description provided for @forecastInsufficientProgress.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =0{0 jour sur {total}} =1{1 jour sur {total}} other{{days} jours sur {total}}}'**
  String forecastInsufficientProgress(int days, int total);

  /// No description provided for @forecastInsufficientLeft.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Encore 1 jour} other{Encore {count} jours}}'**
  String forecastInsufficientLeft(int count);

  /// No description provided for @forecastTipDaily.
  ///
  /// In fr, this message translates to:
  /// **'Saisis tes dépenses au fil de la journée, même les petites.'**
  String get forecastTipDaily;

  /// No description provided for @forecastTipIncome.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute tes revenus réguliers (salaire, loyers perçus…).'**
  String get forecastTipIncome;

  /// No description provided for @forecastTipFixed.
  ///
  /// In fr, this message translates to:
  /// **'Indique tes charges fixes : loyer, tontine, abonnements.'**
  String get forecastTipFixed;

  /// No description provided for @forecastAddOperation.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une opération'**
  String get forecastAddOperation;

  /// No description provided for @forecastCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Solde actuel'**
  String get forecastCurrent;

  /// No description provided for @forecastExpectedOn.
  ///
  /// In fr, this message translates to:
  /// **'Prévu au {date}'**
  String forecastExpectedOn(String date);

  /// No description provided for @forecastRange.
  ///
  /// In fr, this message translates to:
  /// **'Entre {low} et {high} FCFA'**
  String forecastRange(String low, String high);

  /// No description provided for @forecastReliability.
  ///
  /// In fr, this message translates to:
  /// **'Fiabilité {level}'**
  String forecastReliability(String level);

  /// No description provided for @forecastReliabilityHigh.
  ///
  /// In fr, this message translates to:
  /// **'élevée'**
  String get forecastReliabilityHigh;

  /// No description provided for @forecastReliabilityMedium.
  ///
  /// In fr, this message translates to:
  /// **'moyenne'**
  String get forecastReliabilityMedium;

  /// No description provided for @forecastReliabilityLow.
  ///
  /// In fr, this message translates to:
  /// **'faible'**
  String get forecastReliabilityLow;

  /// No description provided for @forecastToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get forecastToday;

  /// No description provided for @forecastLegendPast.
  ///
  /// In fr, this message translates to:
  /// **'Passé'**
  String get forecastLegendPast;

  /// No description provided for @forecastLegendEstimate.
  ///
  /// In fr, this message translates to:
  /// **'Estimation'**
  String get forecastLegendEstimate;

  /// No description provided for @forecastLegendRange.
  ///
  /// In fr, this message translates to:
  /// **'Fourchette probable'**
  String get forecastLegendRange;

  /// No description provided for @forecastChartLabel.
  ///
  /// In fr, this message translates to:
  /// **'Solde estimé jusqu\'au {date} : environ {amount} FCFA'**
  String forecastChartLabel(String date, String amount);

  /// No description provided for @forecastRisks.
  ///
  /// In fr, this message translates to:
  /// **'Risques détectés'**
  String get forecastRisks;

  /// No description provided for @forecastRiskCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 point de vigilance} other{{count} points de vigilance}}'**
  String forecastRiskCount(int count);

  /// No description provided for @forecastNoNegative.
  ///
  /// In fr, this message translates to:
  /// **'Aucun solde négatif prévu d\'ici le {date}.'**
  String forecastNoNegative(String date);

  /// No description provided for @forecastNegative.
  ///
  /// In fr, this message translates to:
  /// **'Solde négatif possible le {date}.'**
  String forecastNegative(String date);

  /// No description provided for @forecastNegativeAdvice.
  ///
  /// In fr, this message translates to:
  /// **'Reporte une dépense ou prévois un transfert.'**
  String get forecastNegativeAdvice;

  /// No description provided for @forecastLow.
  ///
  /// In fr, this message translates to:
  /// **'{date} : solde bas possible (≈ {amount} FCFA).'**
  String forecastLow(String date, String amount);

  /// No description provided for @forecastLowBeforeIncome.
  ///
  /// In fr, this message translates to:
  /// **'Juste avant ton salaire. Évite les grosses dépenses d\'ici là.'**
  String get forecastLowBeforeIncome;

  /// No description provided for @forecastLowAdvice.
  ///
  /// In fr, this message translates to:
  /// **'Évite les grosses dépenses d\'ici là.'**
  String get forecastLowAdvice;

  /// No description provided for @forecastBudget.
  ///
  /// In fr, this message translates to:
  /// **'{name} : budget dépassé vers le {date}'**
  String forecastBudget(String name, String date);

  /// No description provided for @forecastBudgetPace.
  ///
  /// In fr, this message translates to:
  /// **'au rythme actuel (≈ {amount} FCFA par jour).'**
  String forecastBudgetPace(String amount);

  /// No description provided for @forecastSeeBudget.
  ///
  /// In fr, this message translates to:
  /// **'Voir le budget'**
  String get forecastSeeBudget;

  /// No description provided for @forecastExpected.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui est attendu'**
  String get forecastExpected;

  /// No description provided for @forecastRecurring.
  ///
  /// In fr, this message translates to:
  /// **'Récurrentes'**
  String get forecastRecurring;

  /// No description provided for @forecastExpectedIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenus attendus'**
  String get forecastExpectedIncome;

  /// No description provided for @forecastExpectedExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses attendues'**
  String get forecastExpectedExpenses;

  /// No description provided for @forecastNoRecurring.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération récurrente dans la période.'**
  String get forecastNoRecurring;

  /// No description provided for @forecastEveryDay.
  ///
  /// In fr, this message translates to:
  /// **'Chaque jour'**
  String get forecastEveryDay;

  /// No description provided for @forecastVariable.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses variables'**
  String get forecastVariable;

  /// No description provided for @forecastVariableHelp.
  ///
  /// In fr, this message translates to:
  /// **'Estimées sur tes 3 derniers mois'**
  String get forecastVariableHelp;

  /// No description provided for @forecastHowTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment est calculée cette prévision ?'**
  String get forecastHowTitle;

  /// No description provided for @forecastHowRecurring.
  ///
  /// In fr, this message translates to:
  /// **'Les opérations récurrentes actives arrivent à leur date.'**
  String get forecastHowRecurring;

  /// No description provided for @forecastHowNoRecurring.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération récurrente n\'est programmée : seules tes dépenses courantes sont projetées.'**
  String get forecastHowNoRecurring;

  /// No description provided for @forecastHowVariable.
  ///
  /// In fr, this message translates to:
  /// **'Tes dépenses courantes restent proches de ta moyenne (≈ {amount} FCFA par jour).'**
  String forecastHowVariable(String amount);

  /// No description provided for @forecastHowIncome.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les revenus récurrents sont comptés, par prudence.'**
  String get forecastHowIncome;

  /// No description provided for @forecastHowNoException.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dépense exceptionnelle n\'est prévue.'**
  String get forecastHowNoException;

  /// No description provided for @forecastDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'C\'est une estimation, pas une certitude : plus l\'horizon est lointain, plus la fourchette s\'élargit. Calculé sur ton téléphone.'**
  String get forecastDisclaimer;

  /// No description provided for @budgetSeeForecast.
  ///
  /// In fr, this message translates to:
  /// **'Voir la prévision'**
  String get budgetSeeForecast;

  /// No description provided for @budgetsSegment.
  ///
  /// In fr, this message translates to:
  /// **'Budgets'**
  String get budgetsSegment;

  /// No description provided for @goalsSegment.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs'**
  String get goalsSegment;

  /// No description provided for @goalsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Mis de côté'**
  String get goalsSaved;

  /// No description provided for @goalsOfTarget.
  ///
  /// In fr, this message translates to:
  /// **'/ {target} FCFA'**
  String goalsOfTarget(String target);

  /// No description provided for @goalsInProgress.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun objectif en cours} =1{1 objectif en cours} other{{count} objectifs en cours}}'**
  String goalsInProgress(int count);

  /// No description provided for @goalDue.
  ///
  /// In fr, this message translates to:
  /// **'Échéance : {date}'**
  String goalDue(String date);

  /// No description provided for @goalNoDue.
  ///
  /// In fr, this message translates to:
  /// **'Sans échéance'**
  String get goalNoDue;

  /// No description provided for @goalDueHistory.
  ///
  /// In fr, this message translates to:
  /// **'{due} · historique et retraits'**
  String goalDueHistory(String due);

  /// No description provided for @goalAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get goalAdd;

  /// No description provided for @goalWithdraw.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get goalWithdraw;

  /// No description provided for @goalSavedOf.
  ///
  /// In fr, this message translates to:
  /// **'sur {target} FCFA'**
  String goalSavedOf(String target);

  /// No description provided for @goalNoteOnTrack.
  ///
  /// In fr, this message translates to:
  /// **'Environ {amount} FCFA par mois pour y arriver à temps.'**
  String goalNoteOnTrack(String amount);

  /// No description provided for @goalNoteLate.
  ///
  /// In fr, this message translates to:
  /// **'En retard sur le rythme prévu : il faudrait {amount} FCFA par mois.'**
  String goalNoteLate(String amount);

  /// No description provided for @goalNoteNoDate.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ce que tu peux, quand tu peux.'**
  String get goalNoteNoDate;

  /// No description provided for @goalNoteReached.
  ///
  /// In fr, this message translates to:
  /// **'Objectif atteint. Bravo !'**
  String get goalNoteReached;

  /// No description provided for @goalNoteOverdue.
  ///
  /// In fr, this message translates to:
  /// **'Date dépassée : il reste {amount} FCFA à mettre de côté.'**
  String goalNoteOverdue(String amount);

  /// No description provided for @goalNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel objectif'**
  String get goalNew;

  /// No description provided for @goalsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun objectif pour l\'instant. Mets de l\'argent de côté pour un projet : il reste sur ton compte, simplement réservé.'**
  String get goalsEmpty;

  /// No description provided for @goalAddTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à « {name} »'**
  String goalAddTitle(String name);

  /// No description provided for @goalWithdrawTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de « {name} »'**
  String goalWithdrawTitle(String name);

  /// No description provided for @goalAlreadySaved.
  ///
  /// In fr, this message translates to:
  /// **'Déjà épargné : {saved} sur {target} FCFA'**
  String goalAlreadySaved(String saved, String target);

  /// No description provided for @goalOtherAmount.
  ///
  /// In fr, this message translates to:
  /// **'Autre montant'**
  String get goalOtherAmount;

  /// No description provided for @goalFrom.
  ///
  /// In fr, this message translates to:
  /// **'Depuis'**
  String get goalFrom;

  /// No description provided for @goalTo.
  ///
  /// In fr, this message translates to:
  /// **'Vers'**
  String get goalTo;

  /// No description provided for @goalAccountValue.
  ///
  /// In fr, this message translates to:
  /// **'{name} · {amount} FCFA'**
  String goalAccountValue(String name, String amount);

  /// No description provided for @goalReservedNote.
  ///
  /// In fr, this message translates to:
  /// **'L\'argent reste sur ton compte : il est simplement réservé à cet objectif.'**
  String get goalReservedNote;

  /// No description provided for @goalAddCta.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter {amount} FCFA'**
  String goalAddCta(String amount);

  /// No description provided for @goalWithdrawCta.
  ///
  /// In fr, this message translates to:
  /// **'Retirer {amount} FCFA'**
  String goalWithdrawCta(String amount);

  /// No description provided for @goalWithdrawDelay.
  ///
  /// In fr, this message translates to:
  /// **'Ce retrait repousse ta date estimée d\'environ {weeks, plural, =1{1 semaine} other{{weeks} semaines}}.'**
  String goalWithdrawDelay(int weeks);

  /// No description provided for @goalAddedToast.
  ///
  /// In fr, this message translates to:
  /// **'{amount} FCFA ajoutés à « {name} » · {saved} / {target}'**
  String goalAddedToast(
    String amount,
    String name,
    String saved,
    String target,
  );

  /// No description provided for @goalWithdrawnToast.
  ///
  /// In fr, this message translates to:
  /// **'{amount} FCFA retirés. Effort mis à jour.'**
  String goalWithdrawnToast(String amount);

  /// No description provided for @goalAmountTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Montant supérieur à ce qui est disponible sur ce compte.'**
  String get goalAmountTooLarge;

  /// No description provided for @goalNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte disponible.'**
  String get goalNoAccount;

  /// No description provided for @goalNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel objectif'**
  String get goalNewTitle;

  /// No description provided for @goalEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'objectif'**
  String get goalEditTitle;

  /// No description provided for @goalCreatedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Objectif créé'**
  String get goalCreatedTitle;

  /// No description provided for @goalNameQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Pour quoi épargnes-tu ?'**
  String get goalNameQuestion;

  /// No description provided for @goalNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : Téléphone'**
  String get goalNameHint;

  /// No description provided for @goalTarget.
  ///
  /// In fr, this message translates to:
  /// **'Montant à atteindre'**
  String get goalTarget;

  /// No description provided for @goalDueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get goalDueLabel;

  /// No description provided for @goalDue3.
  ///
  /// In fr, this message translates to:
  /// **'3 mois'**
  String get goalDue3;

  /// No description provided for @goalDue6.
  ///
  /// In fr, this message translates to:
  /// **'6 mois'**
  String get goalDue6;

  /// No description provided for @goalDue12.
  ///
  /// In fr, this message translates to:
  /// **'1 an'**
  String get goalDue12;

  /// No description provided for @goalDueNone.
  ///
  /// In fr, this message translates to:
  /// **'Sans date'**
  String get goalDueNone;

  /// No description provided for @goalPlan.
  ///
  /// In fr, this message translates to:
  /// **'Il faudra mettre de côté environ {amount} FCFA par mois.'**
  String goalPlan(String amount);

  /// No description provided for @goalSurplus.
  ///
  /// In fr, this message translates to:
  /// **'En moyenne, il te reste {amount} FCFA par mois après tes dépenses.'**
  String goalSurplus(String amount);

  /// No description provided for @goalTooMuch.
  ///
  /// In fr, this message translates to:
  /// **'Il faudrait {amount} FCFA par mois, plus que ce qu\'il te reste en moyenne ({surplus} FCFA). Choisis une échéance plus lointaine.'**
  String goalTooMuch(String amount, String surplus);

  /// No description provided for @goalCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer l\'objectif'**
  String get goalCreate;

  /// No description provided for @goalSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get goalSave;

  /// No description provided for @goalCreatedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Objectif « {name} » créé'**
  String goalCreatedMessage(String name);

  /// No description provided for @goalCreatedDetail.
  ///
  /// In fr, this message translates to:
  /// **'{amount} FCFA · {due}'**
  String goalCreatedDetail(String amount, String due);

  /// No description provided for @goalCreatedDue.
  ///
  /// In fr, this message translates to:
  /// **'échéance le {date}'**
  String goalCreatedDue(String date);

  /// No description provided for @goalCreatedNoDue.
  ///
  /// In fr, this message translates to:
  /// **'sans échéance'**
  String get goalCreatedNoDue;

  /// No description provided for @goalSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes objectifs'**
  String get goalSeeAll;

  /// No description provided for @goalTargetDate.
  ///
  /// In fr, this message translates to:
  /// **'Date cible'**
  String get goalTargetDate;

  /// No description provided for @goalTargetDateValue.
  ///
  /// In fr, this message translates to:
  /// **'Date cible : {date}'**
  String goalTargetDateValue(String date);

  /// No description provided for @goalDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cet objectif'**
  String get goalDelete;

  /// No description provided for @goalDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cet objectif ?'**
  String get goalDeleteTitle;

  /// No description provided for @goalDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Les {amount} FCFA réservés sont libérés sur tes comptes. Aucun solde ne change.'**
  String goalDeleteBody(String amount);

  /// No description provided for @goalDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Objectif supprimé.'**
  String get goalDeleted;

  /// No description provided for @goalErrorName.
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom à cet objectif.'**
  String get goalErrorName;

  /// No description provided for @goalErrorTarget.
  ///
  /// In fr, this message translates to:
  /// **'Indique un montant supérieur à 0.'**
  String get goalErrorTarget;

  /// No description provided for @goalErrorDate.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une date après aujourd\'hui.'**
  String get goalErrorDate;

  /// No description provided for @goalLeft.
  ///
  /// In fr, this message translates to:
  /// **'Reste {amount} FCFA'**
  String goalLeft(String amount);

  /// No description provided for @goalEffort.
  ///
  /// In fr, this message translates to:
  /// **'Effort nécessaire'**
  String get goalEffort;

  /// No description provided for @goalPerMonth.
  ///
  /// In fr, this message translates to:
  /// **'FCFA par mois'**
  String get goalPerMonth;

  /// No description provided for @goalPerWeek.
  ///
  /// In fr, this message translates to:
  /// **'FCFA par semaine'**
  String get goalPerWeek;

  /// No description provided for @goalPace.
  ///
  /// In fr, this message translates to:
  /// **'Ces 3 derniers mois, tu as mis de côté ≈ {amount} FCFA par mois.'**
  String goalPace(String amount);

  /// No description provided for @goalComputedBy.
  ///
  /// In fr, this message translates to:
  /// **'Calcul fait par l\'application à partir de tes contributions et retraits.'**
  String get goalComputedBy;

  /// No description provided for @goalHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get goalHistory;

  /// No description provided for @goalContribution.
  ///
  /// In fr, this message translates to:
  /// **'Contribution'**
  String get goalContribution;

  /// No description provided for @goalWithdrawal.
  ///
  /// In fr, this message translates to:
  /// **'Retrait'**
  String get goalWithdrawal;

  /// No description provided for @goalFromAccount.
  ///
  /// In fr, this message translates to:
  /// **'Depuis {name}'**
  String goalFromAccount(String name);

  /// No description provided for @goalToAccount.
  ///
  /// In fr, this message translates to:
  /// **'Vers {name}'**
  String goalToAccount(String name);

  /// No description provided for @goalHistoryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun mouvement pour l\'instant.'**
  String get goalHistoryEmpty;

  /// No description provided for @goalEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get goalEdit;

  /// No description provided for @goalsAccountsLink.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs d\'épargne'**
  String get goalsAccountsLink;

  /// No description provided for @goalsAccountsSummary.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 objectif} other{{count} objectifs}} · {amount} FCFA mis de côté'**
  String goalsAccountsSummary(int count, String amount);

  /// No description provided for @goalSuggestPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get goalSuggestPhone;

  /// No description provided for @goalSuggestEmergency.
  ///
  /// In fr, this message translates to:
  /// **'Fonds d\'urgence'**
  String get goalSuggestEmergency;

  /// No description provided for @goalSuggestTravel.
  ///
  /// In fr, this message translates to:
  /// **'Voyage'**
  String get goalSuggestTravel;

  /// No description provided for @goalSuggestStudies.
  ///
  /// In fr, this message translates to:
  /// **'Études'**
  String get goalSuggestStudies;

  /// No description provided for @goalSuggestWedding.
  ///
  /// In fr, this message translates to:
  /// **'Mariage'**
  String get goalSuggestWedding;

  /// No description provided for @goalSuggestMoto.
  ///
  /// In fr, this message translates to:
  /// **'Moto'**
  String get goalSuggestMoto;

  /// No description provided for @recurringTitle.
  ///
  /// In fr, this message translates to:
  /// **'Opérations récurrentes'**
  String get recurringTitle;

  /// No description provided for @recurringIntroBefore.
  ///
  /// In fr, this message translates to:
  /// **'Ce sont des '**
  String get recurringIntroBefore;

  /// No description provided for @recurringIntroBold.
  ///
  /// In fr, this message translates to:
  /// **'modèles'**
  String get recurringIntroBold;

  /// No description provided for @recurringIntroAfter.
  ///
  /// In fr, this message translates to:
  /// **' : ils servent aux prévisions et te rappellent les échéances, mais ne changent ton solde qu\'une fois l\'opération enregistrée.'**
  String get recurringIntroAfter;

  /// No description provided for @recurringIncomePerMonth.
  ///
  /// In fr, this message translates to:
  /// **'Revenus prévus / mois'**
  String get recurringIncomePerMonth;

  /// No description provided for @recurringExpensePerMonth.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses prévues / mois'**
  String get recurringExpensePerMonth;

  /// No description provided for @recurringPendingToday.
  ///
  /// In fr, this message translates to:
  /// **'À confirmer · échéance aujourd\'hui'**
  String get recurringPendingToday;

  /// No description provided for @recurringPendingYesterday.
  ///
  /// In fr, this message translates to:
  /// **'À confirmer · échéance hier'**
  String get recurringPendingYesterday;

  /// No description provided for @recurringPendingOn.
  ///
  /// In fr, this message translates to:
  /// **'À confirmer · échéance du {date}'**
  String recurringPendingOn(String date);

  /// No description provided for @recurringPendingMeta.
  ///
  /// In fr, this message translates to:
  /// **'Prévue le {date} · {account} · pas encore dans tes opérations'**
  String recurringPendingMeta(String date, String account);

  /// No description provided for @recurringWaitingTurn.
  ///
  /// In fr, this message translates to:
  /// **'À traiter après l\'échéance du {date}.'**
  String recurringWaitingTurn(String date);

  /// No description provided for @recurringRecord.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get recurringRecord;

  /// No description provided for @recurringSkipWeek.
  ///
  /// In fr, this message translates to:
  /// **'Pas cette semaine'**
  String get recurringSkipWeek;

  /// No description provided for @recurringSkipMonth.
  ///
  /// In fr, this message translates to:
  /// **'Pas ce mois-ci'**
  String get recurringSkipMonth;

  /// No description provided for @recurringSkipYear.
  ///
  /// In fr, this message translates to:
  /// **'Pas cette année'**
  String get recurringSkipYear;

  /// No description provided for @recurringModels.
  ///
  /// In fr, this message translates to:
  /// **'Modèles'**
  String get recurringModels;

  /// No description provided for @recurringNext.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine échéance : {date}'**
  String recurringNext(String date);

  /// No description provided for @recurringPaused.
  ///
  /// In fr, this message translates to:
  /// **'En pause · aucune échéance prévue'**
  String get recurringPaused;

  /// No description provided for @recurringFinished.
  ///
  /// In fr, this message translates to:
  /// **'Terminée · plus d\'échéance'**
  String get recurringFinished;

  /// No description provided for @recurringEstimated.
  ///
  /// In fr, this message translates to:
  /// **'montant estimé'**
  String get recurringEstimated;

  /// No description provided for @recurringNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle opération récurrente'**
  String get recurringNew;

  /// No description provided for @recurringEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération récurrente. Programme ton salaire, ton loyer ou ta tontine : l\'appli te rappelle chaque échéance.'**
  String get recurringEmpty;

  /// No description provided for @recurringPausedToast.
  ///
  /// In fr, this message translates to:
  /// **'{name} mise en pause : elle ne compte plus dans les prévisions.'**
  String recurringPausedToast(String name);

  /// No description provided for @recurringResumedToast.
  ///
  /// In fr, this message translates to:
  /// **'{name} réactivée : elle compte à nouveau dans les prévisions.'**
  String recurringResumedToast(String name);

  /// No description provided for @recurringRecordedToast.
  ///
  /// In fr, this message translates to:
  /// **'{name} enregistrée : {amount} FCFA sur {account}.'**
  String recurringRecordedToast(String name, String amount, String account);

  /// No description provided for @recurringSkippedToast.
  ///
  /// In fr, this message translates to:
  /// **'Échéance ignorée. Le modèle reste actif.'**
  String get recurringSkippedToast;

  /// No description provided for @recurringAutoRecorded.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 opération récurrente enregistrée automatiquement.} other{{count} opérations récurrentes enregistrées automatiquement.}}'**
  String recurringAutoRecorded(int count);

  /// No description provided for @recurringMetaWeek.
  ///
  /// In fr, this message translates to:
  /// **'Chaque {weekday}'**
  String recurringMetaWeek(String weekday);

  /// No description provided for @recurringMetaMonth.
  ///
  /// In fr, this message translates to:
  /// **'Chaque mois, le {day}'**
  String recurringMetaMonth(String day);

  /// No description provided for @recurringMetaYear.
  ///
  /// In fr, this message translates to:
  /// **'Chaque année, le {date}'**
  String recurringMetaYear(String date);

  /// No description provided for @recurringDueWeek.
  ///
  /// In fr, this message translates to:
  /// **'Chaque {weekday}'**
  String recurringDueWeek(String weekday);

  /// No description provided for @recurringDueMonth.
  ///
  /// In fr, this message translates to:
  /// **'Le {day} de chaque mois'**
  String recurringDueMonth(String day);

  /// No description provided for @recurringDueYear.
  ///
  /// In fr, this message translates to:
  /// **'Chaque {date}'**
  String recurringDueYear(String date);

  /// No description provided for @recurringNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle récurrence'**
  String get recurringNewTitle;

  /// No description provided for @recurringEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la récurrence'**
  String get recurringEditTitle;

  /// No description provided for @recurringCreatedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Programmée'**
  String get recurringCreatedTitle;

  /// No description provided for @recurringName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get recurringName;

  /// No description provided for @recurringNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : Tontine du quartier'**
  String get recurringNameHint;

  /// No description provided for @recurringAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get recurringAmount;

  /// No description provided for @recurringVariable.
  ///
  /// In fr, this message translates to:
  /// **'Montant variable'**
  String get recurringVariable;

  /// No description provided for @recurringVariableHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : facture d\'électricité. Tu confirmes le montant réel.'**
  String get recurringVariableHelp;

  /// No description provided for @recurringFrequency.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence'**
  String get recurringFrequency;

  /// No description provided for @recurringFreqWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine'**
  String get recurringFreqWeek;

  /// No description provided for @recurringFreqMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get recurringFreqMonth;

  /// No description provided for @recurringFreqYear.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get recurringFreqYear;

  /// No description provided for @recurringDue.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get recurringDue;

  /// No description provided for @recurringStart.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get recurringStart;

  /// No description provided for @recurringEnd.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get recurringEnd;

  /// No description provided for @recurringNoEnd.
  ///
  /// In fr, this message translates to:
  /// **'Sans fin'**
  String get recurringNoEnd;

  /// No description provided for @recurringEndOnDate.
  ///
  /// In fr, this message translates to:
  /// **'À une date'**
  String get recurringEndOnDate;

  /// No description provided for @recurringLastDue.
  ///
  /// In fr, this message translates to:
  /// **'Dernière échéance'**
  String get recurringLastDue;

  /// No description provided for @recurringLastDueValue.
  ///
  /// In fr, this message translates to:
  /// **'{date} · {count} fois'**
  String recurringLastDueValue(String date, int count);

  /// No description provided for @recurringAsk.
  ///
  /// In fr, this message translates to:
  /// **'Me demander avant d\'enregistrer'**
  String get recurringAsk;

  /// No description provided for @recurringAskOn.
  ///
  /// In fr, this message translates to:
  /// **'Une demande apparaît à chaque échéance. Tu ajustes le montant si besoin.'**
  String get recurringAskOn;

  /// No description provided for @recurringAskOff.
  ///
  /// In fr, this message translates to:
  /// **'L\'opération sera enregistrée automatiquement à la date prévue.'**
  String get recurringAskOff;

  /// No description provided for @recurringSave.
  ///
  /// In fr, this message translates to:
  /// **'Programmer'**
  String get recurringSave;

  /// No description provided for @recurringSaveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get recurringSaveChanges;

  /// No description provided for @recurringDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce modèle'**
  String get recurringDelete;

  /// No description provided for @recurringDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce modèle ?'**
  String get recurringDeleteTitle;

  /// No description provided for @recurringDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Les opérations déjà enregistrées restent dans ton historique.'**
  String get recurringDeleteBody;

  /// No description provided for @recurringDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Modèle supprimé.'**
  String get recurringDeleted;

  /// No description provided for @recurringCreatedMessage.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » programmée'**
  String recurringCreatedMessage(String name);

  /// No description provided for @recurringCreatedSummary.
  ///
  /// In fr, this message translates to:
  /// **'{amount} FCFA {schedule} · {account}'**
  String recurringCreatedSummary(
    String amount,
    String schedule,
    String account,
  );

  /// No description provided for @recurringCreatedNext.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine échéance : {date}. Rien n\'est enregistré avant cette date.'**
  String recurringCreatedNext(String date);

  /// No description provided for @recurringSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir les opérations récurrentes'**
  String get recurringSeeAll;

  /// No description provided for @recurringErrorName.
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom à cette opération.'**
  String get recurringErrorName;

  /// No description provided for @recurringErrorAmount.
  ///
  /// In fr, this message translates to:
  /// **'Indique un montant supérieur à 0.'**
  String get recurringErrorAmount;

  /// No description provided for @recurringErrorEnd.
  ///
  /// In fr, this message translates to:
  /// **'La fin doit être après le début.'**
  String get recurringErrorEnd;

  /// No description provided for @recurringErrorAccount.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte n\'est plus disponible.'**
  String get recurringErrorAccount;

  /// No description provided for @recurringErrorCategory.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une catégorie.'**
  String get recurringErrorCategory;

  /// No description provided for @recurringRealAmountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Montant réel : {name}'**
  String recurringRealAmountTitle(String name);

  /// No description provided for @recurringRealAmountHelp.
  ///
  /// In fr, this message translates to:
  /// **'Estimation : {amount} FCFA.'**
  String recurringRealAmountHelp(String amount);

  /// No description provided for @txMakeRecurring.
  ///
  /// In fr, this message translates to:
  /// **'Rendre récurrente'**
  String get txMakeRecurring;

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

  /// No description provided for @txModePaid.
  ///
  /// In fr, this message translates to:
  /// **'Payée'**
  String get txModePaid;

  /// No description provided for @txModePlanned.
  ///
  /// In fr, this message translates to:
  /// **'Planifiée'**
  String get txModePlanned;

  /// No description provided for @txModePaidHint.
  ///
  /// In fr, this message translates to:
  /// **'Déjà payée : elle sort de ton compte à la date choisie.'**
  String get txModePaidHint;

  /// No description provided for @txModePlannedHint.
  ///
  /// In fr, this message translates to:
  /// **'À payer plus tard : rien ne sort de ton compte aujourd\'hui.'**
  String get txModePlannedHint;

  /// No description provided for @plannedName.
  ///
  /// In fr, this message translates to:
  /// **'Libellé'**
  String get plannedName;

  /// No description provided for @plannedNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom à cette dépense pour la retrouver.'**
  String get plannedNameHint;

  /// No description provided for @plannedNameHintExample.
  ///
  /// In fr, this message translates to:
  /// **'Par exemple : Scolarité'**
  String get plannedNameHintExample;

  /// No description provided for @plannedDueDate.
  ///
  /// In fr, this message translates to:
  /// **'Date prévue de paiement'**
  String get plannedDueDate;

  /// No description provided for @plannedDuePickerHelp.
  ///
  /// In fr, this message translates to:
  /// **'Date prévue'**
  String get plannedDuePickerHelp;

  /// No description provided for @plannedInfoSameMonth.
  ///
  /// In fr, this message translates to:
  /// **'Comptée dans les dépenses de {month}. Ton solde actuel ne change pas tant que tu ne la marques pas payée.'**
  String plannedInfoSameMonth(Object month);

  /// No description provided for @plannedInfoLaterMonth.
  ///
  /// In fr, this message translates to:
  /// **'Comptée dans les dépenses de {month}, pas en {current}. Ton solde actuel ne change pas tant que tu ne la marques pas payée.'**
  String plannedInfoLaterMonth(Object current, Object month);

  /// No description provided for @plannedNote.
  ///
  /// In fr, this message translates to:
  /// **'Note (facultative)'**
  String get plannedNote;

  /// No description provided for @plannedAddNote.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une note'**
  String get plannedAddNote;

  /// No description provided for @plannedSave.
  ///
  /// In fr, this message translates to:
  /// **'Planifier la dépense'**
  String get plannedSave;

  /// No description provided for @plannedSavedHeading.
  ///
  /// In fr, this message translates to:
  /// **'Dépense planifiée'**
  String get plannedSavedHeading;

  /// No description provided for @plannedSavedTitle.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » planifiée'**
  String plannedSavedTitle(Object name);

  /// No description provided for @plannedSavedMeta.
  ///
  /// In fr, this message translates to:
  /// **'{category} · {account} · à payer le {date}'**
  String plannedSavedMeta(Object account, Object category, Object date);

  /// No description provided for @plannedSeeExpense.
  ///
  /// In fr, this message translates to:
  /// **'Voir la dépense'**
  String get plannedSeeExpense;

  /// No description provided for @plannedEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la dépense planifiée'**
  String get plannedEditTitle;

  /// No description provided for @plannedUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Dépense planifiée modifiée.'**
  String get plannedUpdated;

  /// No description provided for @plannedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dépense planifiée'**
  String get plannedTitle;

  /// No description provided for @plannedNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Cette dépense planifiée n\'existe plus.'**
  String get plannedNotFound;

  /// No description provided for @plannedStatusPlanned.
  ///
  /// In fr, this message translates to:
  /// **'Planifiée'**
  String get plannedStatusPlanned;

  /// No description provided for @plannedStatusLate.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get plannedStatusLate;

  /// No description provided for @plannedStatusPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payée'**
  String get plannedStatusPaid;

  /// No description provided for @plannedStatusPaidEarly.
  ///
  /// In fr, this message translates to:
  /// **'Payée en avance'**
  String get plannedStatusPaidEarly;

  /// No description provided for @plannedDue.
  ///
  /// In fr, this message translates to:
  /// **'Date prévue'**
  String get plannedDue;

  /// No description provided for @plannedPaidOn.
  ///
  /// In fr, this message translates to:
  /// **'Payée le'**
  String get plannedPaidOn;

  /// No description provided for @plannedNotYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore'**
  String get plannedNotYet;

  /// No description provided for @plannedCreated.
  ///
  /// In fr, this message translates to:
  /// **'Créée le'**
  String get plannedCreated;

  /// No description provided for @plannedNoteRow.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get plannedNoteRow;

  /// No description provided for @plannedImpactPlannedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comptée en {month}, pas avant'**
  String plannedImpactPlannedTitle(Object month);

  /// No description provided for @plannedImpactPlannedText.
  ///
  /// In fr, this message translates to:
  /// **'Elle s\'ajoute aux dépenses planifiées de {month} et à ta prévision, à la date du {date}. Ton solde réel ne change pas tant qu\'elle n\'est pas payée.'**
  String plannedImpactPlannedText(Object date, Object month);

  /// No description provided for @plannedImpactLateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Toujours à payer'**
  String get plannedImpactLateTitle;

  /// No description provided for @plannedImpactLateText.
  ///
  /// In fr, this message translates to:
  /// **'La date prévue est passée. Elle reste dans les dépenses planifiées de {month} et dans tes prévisions, mais elle n\'est pas comptée comme payée.'**
  String plannedImpactLateText(Object month);

  /// No description provided for @plannedMarkPaid.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme payée'**
  String get plannedMarkPaid;

  /// No description provided for @plannedPayDate.
  ///
  /// In fr, this message translates to:
  /// **'Date réelle du paiement'**
  String get plannedPayDate;

  /// No description provided for @plannedPayToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui · {date}'**
  String plannedPayToday(Object date);

  /// No description provided for @plannedPayYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier · {date}'**
  String plannedPayYesterday(Object date);

  /// No description provided for @plannedPayOnDue.
  ///
  /// In fr, this message translates to:
  /// **'À la date prévue · {date}'**
  String plannedPayOnDue(Object date);

  /// No description provided for @plannedPaidFrom.
  ///
  /// In fr, this message translates to:
  /// **'Payée depuis'**
  String get plannedPaidFrom;

  /// No description provided for @plannedPaidFromValue.
  ///
  /// In fr, this message translates to:
  /// **'{account} · {amount} FCFA'**
  String plannedPaidFromValue(Object account, Object amount);

  /// No description provided for @plannedPayEarlyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement anticipé.'**
  String get plannedPayEarlyTitle;

  /// No description provided for @plannedPayEarlyText.
  ///
  /// In fr, this message translates to:
  /// **'Prévue le {due}, payée le {paid} : elle comptera dans les dépenses réelles de {paidMonth} et sortira des prévisions de {dueMonth}. La date prévue reste dans l\'historique.'**
  String plannedPayEarlyText(
    Object due,
    Object dueMonth,
    Object paid,
    Object paidMonth,
  );

  /// No description provided for @plannedPayLateText.
  ///
  /// In fr, this message translates to:
  /// **'Payée après la date prévue : elle comptera à sa date réelle, le {date}.'**
  String plannedPayLateText(Object date);

  /// No description provided for @plannedPayConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le paiement'**
  String get plannedPayConfirm;

  /// No description provided for @plannedPaidToast.
  ///
  /// In fr, this message translates to:
  /// **'{name} payée · −{amount} FCFA sur {account}'**
  String plannedPaidToast(Object account, Object amount, Object name);

  /// No description provided for @plannedDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {name} » ?'**
  String plannedDeleteTitle(Object name);

  /// No description provided for @plannedDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Elle sort des dépenses planifiées de {month} et de tes prévisions. Aucun argent n\'a bougé : ton solde ne change pas.'**
  String plannedDeleteBody(Object month);

  /// No description provided for @plannedDeletedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dépense planifiée supprimée'**
  String get plannedDeletedTitle;

  /// No description provided for @plannedDeletedBody.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » ne compte plus dans les dépenses de {month} ni dans tes prévisions. Aucun argent n\'a bougé.'**
  String plannedDeletedBody(Object month, Object name);

  /// No description provided for @plannedDueMissingFuture.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une date après aujourd\'hui. Pour une dépense déjà faite, choisis « Payée ».'**
  String get plannedDueMissingFuture;

  /// No description provided for @plannedLateGroup.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get plannedLateGroup;

  /// No description provided for @plannedUpcomingGroup.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get plannedUpcomingGroup;

  /// No description provided for @plannedGroupTotal.
  ///
  /// In fr, this message translates to:
  /// **'{amount} à payer'**
  String plannedGroupTotal(Object amount);

  /// No description provided for @plannedLateMeta.
  ///
  /// In fr, this message translates to:
  /// **'Prévue le {date} · {account}'**
  String plannedLateMeta(Object account, Object date);

  /// No description provided for @plannedUpcomingMeta.
  ///
  /// In fr, this message translates to:
  /// **'{date} · {account}'**
  String plannedUpcomingMeta(Object account, Object date);

  /// No description provided for @txPlannedDue.
  ///
  /// In fr, this message translates to:
  /// **'Date prévue'**
  String get txPlannedDue;

  /// No description provided for @txDeletePlannedNote.
  ///
  /// In fr, this message translates to:
  /// **'La dépense planifiée qu\'elle a payée sera supprimée aussi.'**
  String get txDeletePlannedNote;

  /// No description provided for @forecastHowPlanned.
  ///
  /// In fr, this message translates to:
  /// **'Tes dépenses planifiées sont comptées à leur date prévue ; celles en retard, dès demain.'**
  String get forecastHowPlanned;

  /// No description provided for @ntPlannedTitle.
  ///
  /// In fr, this message translates to:
  /// **'{name} · {amount} FCFA à payer aujourd\'hui'**
  String ntPlannedTitle(Object amount, Object name);

  /// No description provided for @ntPlannedBody.
  ///
  /// In fr, this message translates to:
  /// **'Dépense planifiée : marque-la payée une fois réglée.'**
  String get ntPlannedBody;
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
