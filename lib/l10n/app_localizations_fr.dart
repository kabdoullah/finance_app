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
  String get txAllAccounts => 'Tous les comptes';

  @override
  String get txAllCategories => 'Toutes catégories';

  @override
  String get txChooseCategory => 'Choisir une catégorie';

  @override
  String get txFilterExpenseSection => 'Dépenses';

  @override
  String get txFilterIncomeSection => 'Revenus';

  @override
  String txArchivedAccount(String name) {
    return '$name (archivé)';
  }

  @override
  String txNoFilterMatch(String month) {
    return 'Aucune opération ne correspond à ces filtres en $month.';
  }

  @override
  String get txResetFilters => 'Réinitialiser les filtres';

  @override
  String get settingsCategoriesHint => 'Dépenses et revenus, sous-catégories';

  @override
  String get categoriesTitle => 'Catégories';

  @override
  String get categoriesNew => 'Nouvelle catégorie';

  @override
  String get categoriesNewSub => 'Nouvelle sous-catégorie';

  @override
  String get categoryCustom => 'Personnalisée';

  @override
  String get categoryHidden => 'Masquée';

  @override
  String categorySubCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sous-catégories',
      one: '1 sous-catégorie',
      zero: 'Aucune sous-catégorie',
    );
    return '$_temp0';
  }

  @override
  String get categoryAddSub => 'Ajouter';

  @override
  String get categoriesFootnote =>
      'Les catégories prédéfinies ne peuvent pas être supprimées, seulement masquées. Une catégorie personnalisée supprimée renvoie ses opérations vers « Autre ».';

  @override
  String get categoryName => 'Nom';

  @override
  String get categoryNameHint => 'Ex. : Tontine, Cadeaux, Moto';

  @override
  String get categoryAttachTo => 'Rattacher à';

  @override
  String get categoryNoParent => 'Aucune (principale)';

  @override
  String get categoryIcon => 'Icône';

  @override
  String get categoryCreate => 'Créer la catégorie';

  @override
  String categoryAddTo(String parent) {
    return 'Ajouter à $parent';
  }

  @override
  String categoryCreated(String name) {
    return 'Catégorie « $name » créée.';
  }

  @override
  String categorySubCreated(String name, String parent) {
    return 'Sous-catégorie « $name » ajoutée à $parent.';
  }

  @override
  String get categoryRename => 'Renommer';

  @override
  String categoryRenameTitle(String name) {
    return 'Renommer « $name »';
  }

  @override
  String get categoryHide => 'Masquer';

  @override
  String get categoryShow => 'Réafficher';

  @override
  String get categoryDelete => 'Supprimer';

  @override
  String categoryHiddenToast(String name) {
    return '« $name » est masquée : elle n\'est plus proposée à la saisie.';
  }

  @override
  String categoryShownToast(String name) {
    return '« $name » est de nouveau proposée.';
  }

  @override
  String categoryDeleteTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String categoryDeleteBody(int count, String target) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ses $count opérations passeront dans « $target ».',
      one: 'Son opération passera dans « $target ».',
      zero: 'Aucune opération ne l\'utilise.',
    );
    return '$_temp0 Cette action est définitive.';
  }

  @override
  String get categoryDeleted => 'Catégorie supprimée.';

  @override
  String get categoryErrorNameMissing => 'Donne un nom à la catégorie.';

  @override
  String get categoryErrorNameTooLong => '40 caractères maximum.';

  @override
  String get categoryErrorNameTaken => 'Une catégorie porte déjà ce nom ici.';

  @override
  String categoryIconLabel(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'tag': 'Étiquette',
      'gift': 'Cadeau',
      'hand_coins': 'Argent',
      'device_mobile': 'Téléphone',
      'heartbeat': 'Santé',
      'graduation_cap': 'Études',
      'users': 'Famille',
      't_shirt': 'Vêtements',
      'house_line': 'Maison',
      'ticket': 'Sortie',
      'taxi': 'Transport',
      'basket': 'Courses',
      'other': 'Icône',
    });
    return '$_temp0';
  }

  @override
  String get budgetsTitle => 'Budgets';

  @override
  String budgetMonthTitle(String month) {
    return 'Budget de $month';
  }

  @override
  String budgetOfLimit(String limit) {
    return '/ $limit FCFA';
  }

  @override
  String budgetRemainingSentence(String amount, String perDay) {
    return 'Il te reste $amount FCFA jusqu\'à la fin du mois, soit environ $perDay FCFA par jour.';
  }

  @override
  String budgetOverSentence(String amount) {
    return 'Budget du mois dépassé de $amount FCFA.';
  }

  @override
  String budgetDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encore $count jours',
      one: 'Dernier jour',
    );
    return '$_temp0';
  }

  @override
  String get budgetNoGlobal => 'Définir un budget pour tout le mois';

  @override
  String budgetExceededAlert(String name, String amount) {
    return '$name : budget dépassé de $amount FCFA.';
  }

  @override
  String get budgetByCategory => 'Par catégorie';

  @override
  String budgetDriver(String name, int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opérations',
      one: '1 opération',
    );
    return 'Surtout à cause de $name : $_temp0, $amount FCFA ce mois-ci.';
  }

  @override
  String get budgetForecastLabel => 'Prévision :';

  @override
  String budgetForecastLead(String items) {
    return 'au rythme actuel, $items.';
  }

  @override
  String budgetForecastCategory(String name, String date) {
    return '$name dépassera son budget vers le $date';
  }

  @override
  String budgetForecastGlobal(String date) {
    return 'le budget du mois sera dépassé vers le $date';
  }

  @override
  String get listAnd => 'et';

  @override
  String budgetSpentOf(String spent, String limit) {
    return '$spent sur $limit';
  }

  @override
  String budgetRemaining(String amount) {
    return '$amount restants';
  }

  @override
  String budgetExceeded(String amount) {
    return 'Dépassé de $amount';
  }

  @override
  String get budgetPaid => 'Payé';

  @override
  String budgetWithout(String names) {
    return 'Sans budget : $names';
  }

  @override
  String get budgetCreate => 'Créer un budget';

  @override
  String get budgetSeeOperations => 'Voir les opérations';

  @override
  String get budgetEmpty =>
      'Aucun budget pour l\'instant. Fixe une limite par mois pour suivre tes dépenses.';

  @override
  String get budgetNewTitle => 'Création d\'un budget';

  @override
  String get budgetEditTitle => 'Modifier le budget';

  @override
  String get budgetAllExpenses => 'Toutes les dépenses';

  @override
  String budgetAlreadyTracked(String names) {
    return 'Déjà suivies : $names';
  }

  @override
  String get budgetLimit => 'Limite par mois';

  @override
  String budgetAverage(String amount) {
    return 'Ces 3 derniers mois, tu as dépensé en moyenne $amount FCFA.';
  }

  @override
  String get budgetUseAmount => 'Utiliser ce montant';

  @override
  String get budgetPeriod => 'Période';

  @override
  String get budgetPeriodMonthly => 'Chaque mois, à partir du 1er';

  @override
  String get budgetAlertAt => 'M\'avertir quand j\'atteins';

  @override
  String get budgetSave => 'Créer le budget';

  @override
  String get budgetCreatedTitle => 'Budget créé';

  @override
  String budgetCreatedMessage(String name) {
    return 'Budget $name créé';
  }

  @override
  String get budgetCreatedGlobal => 'Budget du mois créé';

  @override
  String budgetCreatedDetail(String amount, int percent) {
    return '$amount FCFA par mois · alerte à $percent %';
  }

  @override
  String get budgetSeeAll => 'Voir mes budgets';

  @override
  String get budgetAddAnother => 'Créer un autre budget';

  @override
  String get budgetSaveChanges => 'Enregistrer';

  @override
  String get budgetDeleted => 'Budget supprimé.';

  @override
  String get budgetErrorLimit => 'Indique une limite supérieure à 0.';

  @override
  String get budgetErrorExists => 'Cette catégorie a déjà un budget.';

  @override
  String get budgetErrorCategory => 'Choisis une catégorie de dépenses.';

  @override
  String get budgetDelete => 'Supprimer ce budget';

  @override
  String get budgetDeleteTitle => 'Supprimer ce budget ?';

  @override
  String get budgetDeleteBody =>
      'Tes opérations ne sont pas modifiées : seul le suivi de la limite disparaît.';

  @override
  String budgetImpactLeft(String amount, String name) {
    return 'Il te reste $amount FCFA dans ton budget $name.';
  }

  @override
  String budgetImpactOver(String name, String amount) {
    return 'Ton budget $name est maintenant dépassé de $amount FCFA.';
  }

  @override
  String get dashboardWhereMoney => 'Où va ton argent';

  @override
  String dashboardShare(int percent) {
    return '$percent %';
  }

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
