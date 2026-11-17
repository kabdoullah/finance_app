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
      'Tu peux aussi l\'écrire simplement : « J\'ai 25 000 FCFA sur Wave ».';

  @override
  String get dashboardCopilotAction => 'Écrire au Copilote';

  @override
  String get dashboardPrivacyNote =>
      'Tes données restent sur ce téléphone. Les prévisions apparaîtront après environ deux semaines d\'opérations.';

  @override
  String dashboardAccountsLink(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Répartis sur $count comptes',
      one: 'Réparti sur 1 compte',
    );
    return '$_temp0';
  }

  @override
  String get currencyLabel => 'FCFA';

  @override
  String get cancel => 'Annuler';

  @override
  String get errorGeneric => 'Une erreur est survenue. Réessaie.';

  @override
  String get accountTypeCash => 'Espèces';

  @override
  String get accountTypeMobileMoney => 'Mobile Money';

  @override
  String get accountTypeBank => 'Banque';

  @override
  String get accountTypeSavings => 'Épargne';

  @override
  String get accountsTitle => 'Mes comptes';

  @override
  String get accountsAdd => 'Ajouter un compte';

  @override
  String get accountsTotal => 'Total des comptes';

  @override
  String accountsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comptes',
      one: '1 compte',
      zero: 'Aucun compte',
    );
    return '$_temp0';
  }

  @override
  String accountsDistribution(String parts) {
    return 'Répartition : $parts';
  }

  @override
  String accountsShare(String name, int percent) {
    return '$name $percent %';
  }

  @override
  String get accountsOthers => 'Autres';

  @override
  String get accountsArchived => 'Archivés';

  @override
  String get accountsAddSavings => 'Ajouter un compte épargne';

  @override
  String get accountsAddSavingsHint => 'Tontine, livret, coffre…';

  @override
  String get accountsEmpty => 'Aucun compte pour l\'instant.';

  @override
  String get accountNoOperation => 'Aucune opération pour l\'instant';

  @override
  String accountArchivedOn(String date) {
    return 'Archivé le $date · historique conservé';
  }

  @override
  String get accountNewTitle => 'Nouveau compte';

  @override
  String get accountEditTitle => 'Modifier le compte';

  @override
  String get accountCreatedTitle => 'Compte créé';

  @override
  String get accountFieldType => 'Type de compte';

  @override
  String get accountFieldOperator => 'Opérateur';

  @override
  String get accountFieldName => 'Nom du compte';

  @override
  String get accountFieldCurrentBalance => 'Solde actuel';

  @override
  String get accountFieldOpeningBalance => 'Solde initial';

  @override
  String get accountOpeningBalanceHelp =>
      'Ce montant de départ n\'est pas compté comme un revenu.';

  @override
  String get accountNameHintNone => 'Choisis d\'abord un type';

  @override
  String get accountNameHintCash => 'Portefeuille';

  @override
  String get accountNameHintMobileMoney => 'Ex. : Wave';

  @override
  String get accountNameHintBank => 'Ex. : Ecobank';

  @override
  String get accountNameHintSavings => 'Ex. : Tontine du quartier';

  @override
  String get accountCreate => 'Créer le compte';

  @override
  String get accountSave => 'Enregistrer';

  @override
  String accountCreatedMessage(String name) {
    return 'Compte « $name » créé';
  }

  @override
  String accountCreatedBalance(String amount) {
    return 'Solde de départ : $amount FCFA';
  }

  @override
  String get accountSeeAll => 'Voir mes comptes';

  @override
  String get accountAddAnother => 'Ajouter un autre compte';

  @override
  String get accountErrorNameMissing => 'Donne un nom au compte.';

  @override
  String get accountErrorNameTooLong => '40 caractères maximum.';

  @override
  String get accountErrorNameTaken => 'Tu as déjà un compte actif à ce nom.';

  @override
  String get accountErrorOpeningBalance => 'Montant trop élevé.';

  @override
  String get accountErrorNotFound => 'Ce compte n\'existe plus.';

  @override
  String get accountEditAction => 'Modifier';

  @override
  String accountTypeAndName(String type, String name) {
    return '$type · $name';
  }

  @override
  String accountOpeningInfo(String amount, String date) {
    return 'Solde initial : $amount FCFA, saisi le $date.';
  }

  @override
  String accountArchivedInfo(String date) {
    return 'Archivé le $date. Il n\'apparaît plus dans tes listes ni dans ton total.';
  }

  @override
  String get accountArchive => 'Archiver ce compte';

  @override
  String get accountRestore => 'Restaurer ce compte';

  @override
  String get accountRestored => 'Compte restauré.';

  @override
  String get accountRestoreNameTaken =>
      'Un compte actif porte déjà ce nom : renomme celui-ci avant de le restaurer.';

  @override
  String get accountDelete => 'Supprimer ce compte';

  @override
  String accountArchiveTitle(String name) {
    return 'Archiver le compte $name ?';
  }

  @override
  String get accountArchiveBody =>
      'Il disparaît de tes listes et de ton total, mais son historique reste consultable dans Comptes › Archivés. Tu pourras le restaurer à tout moment.';

  @override
  String get accountArchiveConfirm => 'Archiver';

  @override
  String accountDeleteTitle(String name) {
    return 'Supprimer le compte $name ?';
  }

  @override
  String accountDeleteBody(String amount) {
    return 'Ton solde total baissera de $amount FCFA. Cette action est définitive. Pour garder l\'historique, archive-le plutôt.';
  }

  @override
  String get accountDeleteBodyArchived =>
      'Cette action est définitive : son historique sera perdu.';

  @override
  String accountDeleteBodyWithOperations(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ses $count opérations seront aussi supprimées',
      one: 'Son opération sera aussi supprimée',
    );
    return '$_temp0 et ton solde total baissera de $amount FCFA. Cette action est définitive. Pour garder l\'historique, archive-le plutôt.';
  }

  @override
  String accountLastOperation(String when) {
    return 'Dernière opération : $when';
  }

  @override
  String accountMonthIn(String month) {
    return 'Arrivées en $month';
  }

  @override
  String accountMonthOut(String month) {
    return 'Sorties en $month';
  }

  @override
  String accountTransfersNote(String amount) {
    return 'Dont $amount FCFA de transferts entre tes comptes, exclus de tes revenus et dépenses.';
  }

  @override
  String get accountHistory => 'Historique des mouvements';

  @override
  String get accountNoHistory => 'Aucun mouvement pour l\'instant.';

  @override
  String get accountNewOperation => 'Opération';

  @override
  String get accountNewTransfer => 'Transférer';

  @override
  String accountBalanceAfterShort(String amount) {
    return 'Solde $amount';
  }

  @override
  String get accountInternalTransfer => 'Transfert interne';

  @override
  String get today => 'aujourd\'hui';

  @override
  String get yesterday => 'hier';

  @override
  String get dayToday => 'Aujourd\'hui';

  @override
  String get dayYesterday => 'Hier';

  @override
  String dayHeaderRelative(String day, String date) {
    return '$day · $date';
  }

  @override
  String atTime(String day, String time) {
    return '$day à $time';
  }

  @override
  String get txKindExpense => 'Dépense';

  @override
  String get txKindIncome => 'Revenu';

  @override
  String get txKindTransfer => 'Transfert';

  @override
  String get txKindExpenseHint => 'Achat, facture, retrait';

  @override
  String get txKindIncomeHint => 'Salaire, vente, argent reçu';

  @override
  String get txKindTransferHint => 'Entre deux de tes comptes';

  @override
  String get txAdd => 'Ajouter';

  @override
  String get txNewTitle => 'Nouvelle opération';

  @override
  String get txSavedTitle => 'Opération enregistrée';

  @override
  String get txAmount => 'Montant';

  @override
  String get txContinue => 'Continuer';

  @override
  String get txChange => 'Modifier';

  @override
  String get txCategory => 'Catégorie';

  @override
  String get txSubcategory => 'Sous-catégorie';

  @override
  String get txNoSubcategory => 'Aucune';

  @override
  String get txAccount => 'Compte';

  @override
  String get txFrom => 'Depuis';

  @override
  String get txTo => 'Vers';

  @override
  String get txDate => 'Date';

  @override
  String get txDescription => 'Description';

  @override
  String get txAddDescription => 'Ajouter une description';

  @override
  String get txDescriptionHint => 'Ex. : taxi pour le bureau';

  @override
  String get txTransferInfo =>
      'Un transfert entre tes comptes ne compte ni comme revenu ni comme dépense : ton solde total ne change pas.';

  @override
  String get txSaveExpense => 'Enregistrer la dépense';

  @override
  String get txSaveIncome => 'Enregistrer le revenu';

  @override
  String get txSaveTransfer => 'Enregistrer le transfert';

  @override
  String get txSavedExpense => 'Dépense enregistrée';

  @override
  String get txSavedIncome => 'Revenu enregistré';

  @override
  String get txSavedTransfer => 'Transfert enregistré';

  @override
  String txNewBalance(String account) {
    return 'Nouveau solde $account';
  }

  @override
  String get txBackHome => 'Retour à l\'accueil';

  @override
  String get txAddAnother => 'Ajouter une autre opération';

  @override
  String get txNeedAccount =>
      'Ajoute d\'abord un compte pour enregistrer une opération.';

  @override
  String get txNeedTwoAccounts =>
      'Il faut au moins deux comptes actifs pour faire un transfert.';

  @override
  String get txChooseAccount => 'Choisir un compte';

  @override
  String get txAccountUnavailable =>
      'Ce compte n\'est plus disponible : choisis-en un autre.';

  @override
  String txTransferTitle(String account) {
    return 'Vers $account';
  }

  @override
  String txTransferMeta(String from, String to) {
    return 'Transfert · $from → $to';
  }

  @override
  String txMeta(String category, String account) {
    return '$category · $account';
  }

  @override
  String get txListTitle => 'Transactions';

  @override
  String get txSearchHint => 'Rechercher une opération';

  @override
  String get txClearSearch => 'Effacer la recherche';

  @override
  String get txFilterAll => 'Tout';

  @override
  String get txFilterIncome => 'Revenus';

  @override
  String get txFilterExpense => 'Dépenses';

  @override
  String get txFilterTransfer => 'Transferts';

  @override
  String txCountSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opérations',
      one: '1 opération',
      zero: 'Aucune opération',
    );
    return '$_temp0 · transferts exclus des totaux';
  }

  @override
  String get txEmptyTitle => 'Aucune opération pour l\'instant';

  @override
  String get txEmptyBody =>
      'Ajoute ta première dépense ou ton premier revenu. Tu peux aussi l\'écrire au Copilote : « Taxi 2 500 avec Wave ».';

  @override
  String get txEmptyAction => 'Ajouter une opération';

  @override
  String txMonthEmpty(String month) {
    return 'Aucune opération en $month.';
  }

  @override
  String get txNoResultTitle => 'Aucun résultat';

  @override
  String txNoResultBody(String query, String month) {
    return 'Aucune opération ne correspond à « $query » en $month. Essaie un autre mot ou change de période.';
  }

  @override
  String get txChooseMonth => 'Choisir le mois';

  @override
  String get txDetailTitle => 'Opération';

  @override
  String txKindWhen(String kind, String when) {
    return '$kind · $when';
  }

  @override
  String txBalanceAfter(String amount) {
    return 'Solde après : $amount FCFA';
  }

  @override
  String get txEntry => 'Saisie';

  @override
  String get entryManual => 'Manuelle';

  @override
  String get entryVoice => 'Vocale';

  @override
  String get entryText => 'Texte';

  @override
  String get entryReceipt => 'Reçu';

  @override
  String get entryRecurring => 'Récurrente';

  @override
  String get txDuplicate => 'Dupliquer';

  @override
  String get txDuplicated => 'Opération dupliquée.';

  @override
  String get txDelete => 'Supprimer';

  @override
  String txDeleteTitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'expense': 'Supprimer cette dépense ?',
      'income': 'Supprimer ce revenu ?',
      'other': 'Supprimer ce transfert ?',
    });
    return '$_temp0';
  }

  @override
  String txDeleteBody(String title, String amount, String account) {
    return '$title, $amount FCFA. Le solde $account sera recalculé.';
  }

  @override
  String get txDeletedTitle => 'Opération supprimée';

  @override
  String txDeletedBody(String account) {
    return 'Le solde $account a été mis à jour.';
  }

  @override
  String get txUndo => 'Annuler la suppression';

  @override
  String get txBackToList => 'Retour aux transactions';

  @override
  String get txNotFound => 'Cette opération n\'existe plus.';

  @override
  String get dashboardMonthIncome => 'Revenus du mois';

  @override
  String get dashboardMonthExpense => 'Dépenses du mois';

  @override
  String get dashboardRecent => 'Dernières opérations';

  @override
  String get dashboardSeeAll => 'Tout voir';

  @override
  String get accountDeleteConfirm => 'Supprimer définitivement';
}
