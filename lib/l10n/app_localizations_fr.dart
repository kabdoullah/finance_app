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
  String get qeDictate => 'Dicter';

  @override
  String get qeDictateHint => 'Une ou plusieurs opérations';

  @override
  String get qeWrite => 'Écrire';

  @override
  String get qeOrWrite => 'Ou écris-le simplement';

  @override
  String get qeWriteExample => '« Taxi 2 500 ce matin avec Wave »';

  @override
  String get qeWriteNote =>
      'L\'application prépare les opérations, tu vérifies avant d\'enregistrer.';

  @override
  String get qeListening => 'Écoute en cours · reconnaissance hors ligne';

  @override
  String get qeListenHint =>
      'Tu peux dicter plusieurs opérations d\'un coup, avec le compte et la date : « Hier, 2 000 de crédit Orange et 1 500 de pain en espèces ».';

  @override
  String get qeTapToFinish => 'Touche pour terminer';

  @override
  String get qeTapToRetry => 'Touche pour réessayer';

  @override
  String get qeInputPrompt => 'Décris tes opérations avec tes mots';

  @override
  String get qeExamples => 'Exemples';

  @override
  String get qeExample1 => 'Déjeuner 2 500 et taxi 1 000 avec Wave';

  @override
  String get qeExample2 => 'Reçu 45 000 de mon client sur Orange Money';

  @override
  String get qeExample3 => 'Hier, recharge crédit 2 000 en espèces';

  @override
  String get qeAnalyse => 'Analyser';

  @override
  String get qeRecapHeading => 'Vérifier';

  @override
  String get qeRecapTitle => 'Récapitulatif à vérifier';

  @override
  String get qeSimplified =>
      'Analyse simplifiée par l\'application : vérifie bien chaque champ.';

  @override
  String qeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opérations détectées',
      one: '1 opération détectée',
      zero: 'Aucune opération détectée',
    );
    return '$_temp0';
  }

  @override
  String get qeToCheck => 'À vérifier';

  @override
  String get qeAmount => 'Montant';

  @override
  String get qeDescription => 'Description';

  @override
  String get qeAccount => 'Compte';

  @override
  String get qeFrom => 'Depuis';

  @override
  String get qeTo => 'Vers';

  @override
  String get qeDate => 'Date';

  @override
  String get qeDayBeforeYesterday => 'avant-hier';

  @override
  String get qeRemove => 'Retirer cette opération';

  @override
  String get qeAddOperation => 'Ajouter une opération';

  @override
  String get qeTotal => 'Total';

  @override
  String qeSave(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Enregistrer $count opérations',
      one: 'Enregistrer l\'opération',
    );
    return '$_temp0';
  }

  @override
  String get qeNothingSaved => 'Rien n\'est enregistré avant ta confirmation.';

  @override
  String get qeSaveFailed =>
      'L\'enregistrement a échoué. Vérifie les opérations et réessaie.';

  @override
  String get qeDoneHeading => 'Enregistré';

  @override
  String qeDoneTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opérations enregistrées',
      one: 'Opération enregistrée',
    );
    return '$_temp0';
  }

  @override
  String get qeDoneSubtitle => 'Ajoutées à tes opérations.';

  @override
  String get qeSeeTransactions => 'Voir dans Transactions';

  @override
  String get qeDictateAnother => 'Dicter une autre opération';

  @override
  String get qeWriteAnother => 'Écrire une autre opération';

  @override
  String get qeNothingHeard => 'Je n\'ai rien entendu.';

  @override
  String get qeNoOperation =>
      'Aucun montant trouvé. Ajoute une opération ou réessaie.';

  @override
  String get qeMicDenied =>
      'Autorise le micro pour dicter, ou écris tes opérations.';

  @override
  String get qeUnsupported =>
      'La dictée hors connexion n\'est pas disponible sur ce téléphone. Écris tes opérations, c\'est aussi rapide.';

  @override
  String get qeLangTitle => 'Installe le français pour dicter';

  @override
  String get qeLangBody =>
      'La dictée se fait sur ton téléphone, sans Internet. Elle a besoin du français hors connexion, à installer une seule fois.';

  @override
  String get qeLangInstall => 'Installer le français';

  @override
  String get qeLangManual =>
      'Si rien ne se passe : ouvre les paramètres de Gboard › Saisie vocale › Reconnaissance hors connexion, puis ajoute Français.';

  @override
  String get qeLangCheck => 'C\'est installé';

  @override
  String get qeWriteInstead => 'Écrire plutôt';

  @override
  String get qeLangDownloading =>
      'Le français est en cours de téléchargement. Réessaie dans un instant.';

  @override
  String get aiModelTitle => 'Modèle IA';

  @override
  String get aiModelName => 'Gemma 4';

  @override
  String get aiModelMeta => 'Modèle embarqué · 2,5 Go · français';

  @override
  String get aiStatusChecking => 'Vérification…';

  @override
  String get aiStatusUnavailable => 'Indisponible';

  @override
  String get aiStatusNone => 'Non installé';

  @override
  String get aiStatusDownloading => 'Téléchargement';

  @override
  String get aiStatusInstalled => 'Installé';

  @override
  String get aiStatusLoading => 'Chargement';

  @override
  String get aiStatusReady => 'Prêt';

  @override
  String get aiStatusError => 'Erreur';

  @override
  String get aiDescChecking => 'Vérification de ton téléphone…';

  @override
  String get aiDescUnavailable =>
      'L\'assistant IA n\'est pas disponible sur ce téléphone. L\'application reste complète.';

  @override
  String get aiReasonAndroid => 'Il demande Android 11 ou plus récent.';

  @override
  String get aiReason64Bit => 'Il demande un téléphone 64 bits.';

  @override
  String get aiReasonRam => 'Il demande au moins 6 Go de mémoire.';

  @override
  String get aiDescNone =>
      'Téléchargement unique de 2,5 Go (Wi-Fi conseillé). Ensuite, tout fonctionne hors connexion.';

  @override
  String get aiDescDownloading =>
      'Tu peux continuer à utiliser l\'application pendant le téléchargement.';

  @override
  String get aiDescInstalled =>
      'Installé mais pas chargé. Il se charge en quelques secondes à la première question.';

  @override
  String get aiDescLoading =>
      'Chargement du modèle en mémoire, quelques secondes…';

  @override
  String get aiDescReady =>
      'Chargé en mémoire. L\'assistant répond hors connexion.';

  @override
  String get aiDescError => 'Le modèle est installé mais n\'a pas pu démarrer.';

  @override
  String get aiInstall => 'Installer (2,5 Go)';

  @override
  String get aiCancelDownload => 'Annuler le téléchargement';

  @override
  String get aiLoadNow => 'Charger maintenant';

  @override
  String get aiUnload => 'Libérer la mémoire';

  @override
  String get aiRetry => 'Réessayer';

  @override
  String get aiContinueWithout => 'Continuer sans IA';

  @override
  String aiProgress(String received, int percent) {
    return '$received Go sur 2,5 Go · $percent %';
  }

  @override
  String get aiLoadingBar => 'Chargement en mémoire…';

  @override
  String get aiLowMemory =>
      'Mémoire insuffisante. Il faut environ 2 Go libres. Ferme d\'autres applications puis réessaie.';

  @override
  String get aiDownloadFailed =>
      'Le téléchargement a échoué. Vérifie ta connexion et réessaie.';

  @override
  String get aiNoStorage =>
      'Espace insuffisant : il faut environ 3 Go libres sur le téléphone.';

  @override
  String get aiMeteredTitle => 'Tu n\'es pas en Wi-Fi';

  @override
  String get aiMeteredBody =>
      'Le téléchargement utilisera 2,5 Go de données mobiles.';

  @override
  String get aiMeteredConfirm => 'Télécharger quand même';

  @override
  String get aiRoleGemma =>
      'Comprend tes phrases, explique tes chiffres, répond à tes questions.';

  @override
  String get aiRoleAppTitle => 'L\'application';

  @override
  String get aiRoleApp => 'Calcule soldes, budgets, prévisions et simulations.';

  @override
  String get aiWithout =>
      'Sans l\'IA, l\'application reste complète : saisie manuelle et vocale, budgets, prévisions. Seules les réponses en langage naturel sont indisponibles.';

  @override
  String get aiVoiceSection => 'Reconnaissance vocale';

  @override
  String get aiVoiceEngine => 'Moteur de dictée';

  @override
  String get aiVoiceEngineHint => 'Hors ligne, distinct de Gemma';

  @override
  String get aiVoiceReady => 'Prêt';

  @override
  String get aiVoiceMissing => 'Français à installer';

  @override
  String get aiVoiceDownloading => 'Téléchargement';

  @override
  String get aiVoiceUnavailable => 'Indisponible';

  @override
  String get aiVoiceLanguage => 'Langue de dictée';

  @override
  String get aiVoiceFrench => 'Français';

  @override
  String get aiPrefsSection => 'Préférences';

  @override
  String get aiLoadOnStartup => 'Charger l\'IA au démarrage';

  @override
  String get aiLoadOnStartupHint =>
      'Réponses plus rapides, un peu plus de mémoire utilisée';

  @override
  String get aiDelete => 'Supprimer le modèle';

  @override
  String get aiDeleteHint => 'Libère 2,5 Go. Tes données ne sont pas touchées.';

  @override
  String get aiDeleteTitle => 'Supprimer Gemma 4 ?';

  @override
  String get aiDeleteBody =>
      'Le modèle sera retiré du téléphone (2,5 Go libérés). Tes opérations, budgets et objectifs restent intacts. Il faudra le réinstaller pour utiliser l\'assistant.';

  @override
  String get aiDeleteConfirm => 'Supprimer';

  @override
  String get settingsAiSection => 'Assistant IA';

  @override
  String get settingsAiModel => 'Modèle Gemma 4';

  @override
  String get settingsAiModelHint => 'Sur l\'appareil, hors connexion · 2,5 Go';

  @override
  String get settingsVoice => 'Reconnaissance vocale';

  @override
  String get settingsVoiceHint => 'Moteur hors ligne distinct · français';

  @override
  String get settingsVoiceReady => 'Prête';

  @override
  String get txDuplicate => 'Dupliquer';

  @override
  String get simTitle => 'Simuler un achat';

  @override
  String get simWhat => 'Achat envisagé';

  @override
  String get simWhatHint => 'Ex. : Téléphone';

  @override
  String get simPrice => 'Prix';

  @override
  String get simWhen => 'Quand ?';

  @override
  String get simToday => 'Aujourd\'hui';

  @override
  String simAfterIncome(String name, String date) {
    return 'Après « $name » ($date)';
  }

  @override
  String simUseSavings(String name) {
    return 'Utiliser mon épargne « $name »';
  }

  @override
  String simSavingsHelp(String amount) {
    return '$amount FCFA déjà mis de côté';
  }

  @override
  String get simPossible => 'Possible';

  @override
  String get simTight => 'Possible, mais serré';

  @override
  String get simDiscouraged => 'Déconseillé';

  @override
  String simExplainOk(String amount, String date) {
    return 'Ton solde disponible resterait au-dessus de $amount FCFA jusqu\'au $date.';
  }

  @override
  String simExplainTight(String amount, String date) {
    return 'Ton solde disponible resterait positif, mais descendrait à ≈ $amount FCFA le $date. Garde une marge pour les imprévus.';
  }

  @override
  String simExplainNeg(String what, String when, String date) {
    return 'Si tu achètes $what $when, ton solde disponible passerait sous zéro à partir du $date.';
  }

  @override
  String get simExplainNegAdvice =>
      'Utiliser ton épargne ou attendre réduirait le risque.';

  @override
  String get simThisPurchase => 'cet achat';

  @override
  String get simTodayLower => 'aujourd\'hui';

  @override
  String simOnDate(String date) {
    return 'le $date';
  }

  @override
  String get simLowest => 'Solde le plus bas';

  @override
  String simLowestOn(String date) {
    return 'le $date';
  }

  @override
  String simBalanceOn(String date) {
    return 'Solde au $date';
  }

  @override
  String simWithout(String amount) {
    return 'sans achat : ≈ $amount';
  }

  @override
  String simReliability(String level, String period) {
    return 'Fiabilité $level · estimation basée sur $period, pas une certitude.';
  }

  @override
  String simPeriodDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tes $count derniers jours',
      one: 'ton dernier jour',
    );
    return '$_temp0';
  }

  @override
  String simPeriodMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tes $count derniers mois',
      one: 'ton dernier mois',
    );
    return '$_temp0';
  }

  @override
  String get simCreateGoal => 'Créer un objectif pour cet achat';

  @override
  String get simEnterPrice => 'Indique un prix pour voir le résultat.';

  @override
  String get simAvailableNote =>
      'Calculé sur ton solde disponible : l\'argent réservé à tes objectifs est mis de côté.';

  @override
  String get forecastSimulate => 'Simuler un achat';

  @override
  String get forecastSimulateExample =>
      '« Puis-je acheter un téléphone à 150 000 FCFA ? »';

  @override
  String goalAdviceIncome(String amount, String name, String day) {
    return 'Pour tenir la date : verse $amount FCFA le jour de « $name » (le $day)';
  }

  @override
  String goalAdviceMonthly(String amount) {
    return 'Pour tenir la date : verse $amount FCFA chaque mois';
  }

  @override
  String goalAdvicePostpone(String date, String amount) {
    return ', ou repousse la date au $date (≈ $amount par mois)';
  }

  @override
  String goalPostponeButton(String date) {
    return 'Repousser au $date';
  }

  @override
  String goalPostponed(String date) {
    return 'Date repoussée au $date.';
  }

  @override
  String goalEmergencyAdvice(String amount) {
    return 'Objectif conseillé : 3 mois de dépenses (≈ $amount FCFA).';
  }

  @override
  String get goalEmergencyAdviceNoData =>
      'Objectif conseillé : 3 mois de dépenses.';

  @override
  String goalEmergencySuggestion(String amount) {
    return '3 mois de tes dépenses ≈ $amount FCFA.';
  }

  @override
  String accountReserved(String amount) {
    return 'dont $amount réservés';
  }

  @override
  String accountAvailable(String available, String reserved) {
    return 'Disponible : $available FCFA · $reserved réservés aux objectifs';
  }

  @override
  String get forecastTitle => 'Prévisions';

  @override
  String get forecastHorizon7 => '7 jours';

  @override
  String get forecastHorizon30 => '30 jours';

  @override
  String get forecastHorizon90 => '90 jours';

  @override
  String get forecastInsufficientTitle => 'Pas encore assez de données';

  @override
  String get forecastInsufficientBody =>
      'Pour estimer ton solde à venir, l\'appli a besoin d\'environ deux semaines d\'opérations.';

  @override
  String forecastInsufficientProgress(int days, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours sur $total',
      one: '1 jour sur $total',
      zero: '0 jour sur $total',
    );
    return '$_temp0';
  }

  @override
  String forecastInsufficientLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encore $count jours',
      one: 'Encore 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get forecastTipDaily =>
      'Saisis tes dépenses au fil de la journée, même les petites.';

  @override
  String get forecastTipIncome =>
      'Ajoute tes revenus réguliers (salaire, loyers perçus…).';

  @override
  String get forecastTipFixed =>
      'Indique tes charges fixes : loyer, tontine, abonnements.';

  @override
  String get forecastAddOperation => 'Ajouter une opération';

  @override
  String get forecastCurrent => 'Solde actuel';

  @override
  String forecastExpectedOn(String date) {
    return 'Prévu au $date';
  }

  @override
  String forecastRange(String low, String high) {
    return 'Entre $low et $high FCFA';
  }

  @override
  String forecastReliability(String level) {
    return 'Fiabilité $level';
  }

  @override
  String get forecastReliabilityHigh => 'élevée';

  @override
  String get forecastReliabilityMedium => 'moyenne';

  @override
  String get forecastReliabilityLow => 'faible';

  @override
  String get forecastToday => 'Aujourd\'hui';

  @override
  String get forecastLegendPast => 'Passé';

  @override
  String get forecastLegendEstimate => 'Estimation';

  @override
  String get forecastLegendRange => 'Fourchette probable';

  @override
  String forecastChartLabel(String date, String amount) {
    return 'Solde estimé jusqu\'au $date : environ $amount FCFA';
  }

  @override
  String get forecastRisks => 'Risques détectés';

  @override
  String forecastRiskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points de vigilance',
      one: '1 point de vigilance',
    );
    return '$_temp0';
  }

  @override
  String forecastNoNegative(String date) {
    return 'Aucun solde négatif prévu d\'ici le $date.';
  }

  @override
  String forecastNegative(String date) {
    return 'Solde négatif possible le $date.';
  }

  @override
  String get forecastNegativeAdvice =>
      'Reporte une dépense ou prévois un transfert.';

  @override
  String forecastLow(String date, String amount) {
    return '$date : solde bas possible (≈ $amount FCFA).';
  }

  @override
  String get forecastLowBeforeIncome =>
      'Juste avant ton salaire. Évite les grosses dépenses d\'ici là.';

  @override
  String get forecastLowAdvice => 'Évite les grosses dépenses d\'ici là.';

  @override
  String forecastBudget(String name, String date) {
    return '$name : budget dépassé vers le $date';
  }

  @override
  String forecastBudgetPace(String amount) {
    return 'au rythme actuel (≈ $amount FCFA par jour).';
  }

  @override
  String get forecastSeeBudget => 'Voir le budget';

  @override
  String get forecastExpected => 'Ce qui est attendu';

  @override
  String get forecastRecurring => 'Récurrentes';

  @override
  String get forecastExpectedIncome => 'Revenus attendus';

  @override
  String get forecastExpectedExpenses => 'Dépenses attendues';

  @override
  String get forecastNoRecurring =>
      'Aucune opération récurrente dans la période.';

  @override
  String get forecastEveryDay => 'Chaque jour';

  @override
  String get forecastVariable => 'Dépenses variables';

  @override
  String get forecastVariableHelp => 'Estimées sur tes 3 derniers mois';

  @override
  String get forecastHowTitle => 'Comment est calculée cette prévision ?';

  @override
  String get forecastHowRecurring =>
      'Les opérations récurrentes actives arrivent à leur date.';

  @override
  String get forecastHowNoRecurring =>
      'Aucune opération récurrente n\'est programmée : seules tes dépenses courantes sont projetées.';

  @override
  String forecastHowVariable(String amount) {
    return 'Tes dépenses courantes restent proches de ta moyenne (≈ $amount FCFA par jour).';
  }

  @override
  String get forecastHowIncome =>
      'Seuls les revenus récurrents sont comptés, par prudence.';

  @override
  String get forecastHowNoException =>
      'Aucune dépense exceptionnelle n\'est prévue.';

  @override
  String get forecastDisclaimer =>
      'C\'est une estimation, pas une certitude : plus l\'horizon est lointain, plus la fourchette s\'élargit. Calculé sur ton téléphone.';

  @override
  String get budgetSeeForecast => 'Voir la prévision';

  @override
  String get budgetsSegment => 'Budgets';

  @override
  String get goalsSegment => 'Objectifs';

  @override
  String get goalsSaved => 'Mis de côté';

  @override
  String goalsOfTarget(String target) {
    return '/ $target FCFA';
  }

  @override
  String goalsInProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objectifs en cours',
      one: '1 objectif en cours',
      zero: 'Aucun objectif en cours',
    );
    return '$_temp0';
  }

  @override
  String goalDue(String date) {
    return 'Échéance : $date';
  }

  @override
  String get goalNoDue => 'Sans échéance';

  @override
  String goalDueHistory(String due) {
    return '$due · historique et retraits';
  }

  @override
  String get goalAdd => 'Ajouter';

  @override
  String get goalWithdraw => 'Retirer';

  @override
  String goalSavedOf(String target) {
    return 'sur $target FCFA';
  }

  @override
  String goalNoteOnTrack(String amount) {
    return 'Environ $amount FCFA par mois pour y arriver à temps.';
  }

  @override
  String goalNoteLate(String amount) {
    return 'En retard sur le rythme prévu : il faudrait $amount FCFA par mois.';
  }

  @override
  String get goalNoteNoDate => 'Ajoute ce que tu peux, quand tu peux.';

  @override
  String get goalNoteReached => 'Objectif atteint. Bravo !';

  @override
  String goalNoteOverdue(String amount) {
    return 'Date dépassée : il reste $amount FCFA à mettre de côté.';
  }

  @override
  String get goalNew => 'Nouvel objectif';

  @override
  String get goalsEmpty =>
      'Aucun objectif pour l\'instant. Mets de l\'argent de côté pour un projet : il reste sur ton compte, simplement réservé.';

  @override
  String goalAddTitle(String name) {
    return 'Ajouter à « $name »';
  }

  @override
  String goalWithdrawTitle(String name) {
    return 'Retirer de « $name »';
  }

  @override
  String goalAlreadySaved(String saved, String target) {
    return 'Déjà épargné : $saved sur $target FCFA';
  }

  @override
  String get goalOtherAmount => 'Autre montant';

  @override
  String get goalFrom => 'Depuis';

  @override
  String get goalTo => 'Vers';

  @override
  String goalAccountValue(String name, String amount) {
    return '$name · $amount FCFA';
  }

  @override
  String get goalReservedNote =>
      'L\'argent reste sur ton compte : il est simplement réservé à cet objectif.';

  @override
  String goalAddCta(String amount) {
    return 'Ajouter $amount FCFA';
  }

  @override
  String goalWithdrawCta(String amount) {
    return 'Retirer $amount FCFA';
  }

  @override
  String goalWithdrawDelay(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks semaines',
      one: '1 semaine',
    );
    return 'Ce retrait repousse ta date estimée d\'environ $_temp0.';
  }

  @override
  String goalAddedToast(
    String amount,
    String name,
    String saved,
    String target,
  ) {
    return '$amount FCFA ajoutés à « $name » · $saved / $target';
  }

  @override
  String goalWithdrawnToast(String amount) {
    return '$amount FCFA retirés. Effort mis à jour.';
  }

  @override
  String get goalAmountTooLarge =>
      'Montant supérieur à ce qui est disponible sur ce compte.';

  @override
  String get goalNoAccount => 'Aucun compte disponible.';

  @override
  String get goalNewTitle => 'Nouvel objectif';

  @override
  String get goalEditTitle => 'Modifier l\'objectif';

  @override
  String get goalCreatedTitle => 'Objectif créé';

  @override
  String get goalNameQuestion => 'Pour quoi épargnes-tu ?';

  @override
  String get goalNameHint => 'Ex. : Téléphone';

  @override
  String get goalTarget => 'Montant à atteindre';

  @override
  String get goalDueLabel => 'Échéance';

  @override
  String get goalDue3 => '3 mois';

  @override
  String get goalDue6 => '6 mois';

  @override
  String get goalDue12 => '1 an';

  @override
  String get goalDueNone => 'Sans date';

  @override
  String goalPlan(String amount) {
    return 'Il faudra mettre de côté environ $amount FCFA par mois.';
  }

  @override
  String goalSurplus(String amount) {
    return 'En moyenne, il te reste $amount FCFA par mois après tes dépenses.';
  }

  @override
  String goalTooMuch(String amount, String surplus) {
    return 'Il faudrait $amount FCFA par mois, plus que ce qu\'il te reste en moyenne ($surplus FCFA). Choisis une échéance plus lointaine.';
  }

  @override
  String get goalCreate => 'Créer l\'objectif';

  @override
  String get goalSave => 'Enregistrer';

  @override
  String goalCreatedMessage(String name) {
    return 'Objectif « $name » créé';
  }

  @override
  String goalCreatedDetail(String amount, String due) {
    return '$amount FCFA · $due';
  }

  @override
  String goalCreatedDue(String date) {
    return 'échéance le $date';
  }

  @override
  String get goalCreatedNoDue => 'sans échéance';

  @override
  String get goalSeeAll => 'Voir mes objectifs';

  @override
  String get goalTargetDate => 'Date cible';

  @override
  String goalTargetDateValue(String date) {
    return 'Date cible : $date';
  }

  @override
  String get goalDelete => 'Supprimer cet objectif';

  @override
  String get goalDeleteTitle => 'Supprimer cet objectif ?';

  @override
  String goalDeleteBody(String amount) {
    return 'Les $amount FCFA réservés sont libérés sur tes comptes. Aucun solde ne change.';
  }

  @override
  String get goalDeleted => 'Objectif supprimé.';

  @override
  String get goalErrorName => 'Donne un nom à cet objectif.';

  @override
  String get goalErrorTarget => 'Indique un montant supérieur à 0.';

  @override
  String get goalErrorDate => 'Choisis une date après aujourd\'hui.';

  @override
  String goalLeft(String amount) {
    return 'Reste $amount FCFA';
  }

  @override
  String get goalEffort => 'Effort nécessaire';

  @override
  String get goalPerMonth => 'FCFA par mois';

  @override
  String get goalPerWeek => 'FCFA par semaine';

  @override
  String goalPace(String amount) {
    return 'Ces 3 derniers mois, tu as mis de côté ≈ $amount FCFA par mois.';
  }

  @override
  String get goalComputedBy =>
      'Calcul fait par l\'application à partir de tes contributions et retraits.';

  @override
  String get goalHistory => 'Historique';

  @override
  String get goalContribution => 'Contribution';

  @override
  String get goalWithdrawal => 'Retrait';

  @override
  String goalFromAccount(String name) {
    return 'Depuis $name';
  }

  @override
  String goalToAccount(String name) {
    return 'Vers $name';
  }

  @override
  String get goalHistoryEmpty => 'Aucun mouvement pour l\'instant.';

  @override
  String get goalEdit => 'Modifier';

  @override
  String get goalsAccountsLink => 'Objectifs d\'épargne';

  @override
  String goalsAccountsSummary(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objectifs',
      one: '1 objectif',
    );
    return '$_temp0 · $amount FCFA mis de côté';
  }

  @override
  String get goalSuggestPhone => 'Téléphone';

  @override
  String get goalSuggestEmergency => 'Fonds d\'urgence';

  @override
  String get goalSuggestTravel => 'Voyage';

  @override
  String get goalSuggestStudies => 'Études';

  @override
  String get goalSuggestWedding => 'Mariage';

  @override
  String get goalSuggestMoto => 'Moto';

  @override
  String get recurringTitle => 'Opérations récurrentes';

  @override
  String get recurringIntroBefore => 'Ce sont des ';

  @override
  String get recurringIntroBold => 'modèles';

  @override
  String get recurringIntroAfter =>
      ' : ils servent aux prévisions et te rappellent les échéances, mais ne changent ton solde qu\'une fois l\'opération enregistrée.';

  @override
  String get recurringIncomePerMonth => 'Revenus prévus / mois';

  @override
  String get recurringExpensePerMonth => 'Dépenses prévues / mois';

  @override
  String get recurringPendingToday => 'À confirmer · échéance aujourd\'hui';

  @override
  String get recurringPendingYesterday => 'À confirmer · échéance hier';

  @override
  String recurringPendingOn(String date) {
    return 'À confirmer · échéance du $date';
  }

  @override
  String recurringPendingMeta(String date, String account) {
    return 'Prévue le $date · $account · pas encore dans tes opérations';
  }

  @override
  String recurringWaitingTurn(String date) {
    return 'À traiter après l\'échéance du $date.';
  }

  @override
  String get recurringRecord => 'Enregistrer';

  @override
  String get recurringSkipWeek => 'Pas cette semaine';

  @override
  String get recurringSkipMonth => 'Pas ce mois-ci';

  @override
  String get recurringSkipYear => 'Pas cette année';

  @override
  String get recurringModels => 'Modèles';

  @override
  String recurringNext(String date) {
    return 'Prochaine échéance : $date';
  }

  @override
  String get recurringPaused => 'En pause · aucune échéance prévue';

  @override
  String get recurringFinished => 'Terminée · plus d\'échéance';

  @override
  String get recurringEstimated => 'montant estimé';

  @override
  String get recurringNew => 'Nouvelle opération récurrente';

  @override
  String get recurringEmpty =>
      'Aucune opération récurrente. Programme ton salaire, ton loyer ou ta tontine : l\'appli te rappelle chaque échéance.';

  @override
  String recurringPausedToast(String name) {
    return '$name mise en pause : elle ne compte plus dans les prévisions.';
  }

  @override
  String recurringResumedToast(String name) {
    return '$name réactivée : elle compte à nouveau dans les prévisions.';
  }

  @override
  String recurringRecordedToast(String name, String amount, String account) {
    return '$name enregistrée : $amount FCFA sur $account.';
  }

  @override
  String get recurringSkippedToast =>
      'Échéance ignorée. Le modèle reste actif.';

  @override
  String recurringAutoRecorded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opérations récurrentes enregistrées automatiquement.',
      one: '1 opération récurrente enregistrée automatiquement.',
    );
    return '$_temp0';
  }

  @override
  String recurringMetaWeek(String weekday) {
    return 'Chaque $weekday';
  }

  @override
  String recurringMetaMonth(String day) {
    return 'Chaque mois, le $day';
  }

  @override
  String recurringMetaYear(String date) {
    return 'Chaque année, le $date';
  }

  @override
  String recurringDueWeek(String weekday) {
    return 'Chaque $weekday';
  }

  @override
  String recurringDueMonth(String day) {
    return 'Le $day de chaque mois';
  }

  @override
  String recurringDueYear(String date) {
    return 'Chaque $date';
  }

  @override
  String get recurringNewTitle => 'Nouvelle récurrence';

  @override
  String get recurringEditTitle => 'Modifier la récurrence';

  @override
  String get recurringCreatedTitle => 'Programmée';

  @override
  String get recurringName => 'Nom';

  @override
  String get recurringNameHint => 'Ex. : Tontine du quartier';

  @override
  String get recurringAmount => 'Montant';

  @override
  String get recurringVariable => 'Montant variable';

  @override
  String get recurringVariableHelp =>
      'Ex. : facture d\'électricité. Tu confirmes le montant réel.';

  @override
  String get recurringFrequency => 'Fréquence';

  @override
  String get recurringFreqWeek => 'Semaine';

  @override
  String get recurringFreqMonth => 'Mois';

  @override
  String get recurringFreqYear => 'Année';

  @override
  String get recurringDue => 'Échéance';

  @override
  String get recurringStart => 'Début';

  @override
  String get recurringEnd => 'Fin';

  @override
  String get recurringNoEnd => 'Sans fin';

  @override
  String get recurringEndOnDate => 'À une date';

  @override
  String get recurringLastDue => 'Dernière échéance';

  @override
  String recurringLastDueValue(String date, int count) {
    return '$date · $count fois';
  }

  @override
  String get recurringAsk => 'Me demander avant d\'enregistrer';

  @override
  String get recurringAskOn =>
      'Une demande apparaît à chaque échéance. Tu ajustes le montant si besoin.';

  @override
  String get recurringAskOff =>
      'L\'opération sera enregistrée automatiquement à la date prévue.';

  @override
  String get recurringSave => 'Programmer';

  @override
  String get recurringSaveChanges => 'Enregistrer';

  @override
  String get recurringDelete => 'Supprimer ce modèle';

  @override
  String get recurringDeleteTitle => 'Supprimer ce modèle ?';

  @override
  String get recurringDeleteBody =>
      'Les opérations déjà enregistrées restent dans ton historique.';

  @override
  String get recurringDeleted => 'Modèle supprimé.';

  @override
  String recurringCreatedMessage(String name) {
    return '« $name » programmée';
  }

  @override
  String recurringCreatedSummary(
    String amount,
    String schedule,
    String account,
  ) {
    return '$amount FCFA $schedule · $account';
  }

  @override
  String recurringCreatedNext(String date) {
    return 'Prochaine échéance : $date. Rien n\'est enregistré avant cette date.';
  }

  @override
  String get recurringSeeAll => 'Voir les opérations récurrentes';

  @override
  String get recurringErrorName => 'Donne un nom à cette opération.';

  @override
  String get recurringErrorAmount => 'Indique un montant supérieur à 0.';

  @override
  String get recurringErrorEnd => 'La fin doit être après le début.';

  @override
  String get recurringErrorAccount => 'Ce compte n\'est plus disponible.';

  @override
  String get recurringErrorCategory => 'Choisis une catégorie.';

  @override
  String recurringRealAmountTitle(String name) {
    return 'Montant réel : $name';
  }

  @override
  String recurringRealAmountHelp(String amount) {
    return 'Estimation : $amount FCFA.';
  }

  @override
  String get txMakeRecurring => 'Rendre récurrente';

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
