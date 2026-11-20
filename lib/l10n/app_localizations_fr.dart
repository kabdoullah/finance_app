// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Finao';

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
  String get accountOpeningBalanceLocked =>
      'Le solde initial ne peut plus être modifié après la création du compte.';

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
  String get txEmptyTitle => 'Aucune opération pour l\'instant';

  @override
  String get txEmptyBody =>
      'Ajoute ta première dépense, dicte-la, ou planifie une dépense à venir.';

  @override
  String get txEmptyAction => 'Ajouter une opération';

  @override
  String get txNoResultTitle => 'Aucun résultat';

  @override
  String get txFilterExpenseSection => 'Dépenses';

  @override
  String get txFilterIncomeSection => 'Revenus';

  @override
  String txArchivedAccount(String name) {
    return '$name (archivé)';
  }

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
  String get qeLangManualIos =>
      'Ouvre Réglages › Général › Clavier : active Dictée, puis ajoute le clavier Français. Le français hors connexion se télécharge ensuite automatiquement.';

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
  String get aiReasonSystem =>
      'Il demande une version plus récente du système (Android 11 ou iOS 15 au minimum).';

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
  String get qeAnalyseHeading => 'Analyse';

  @override
  String get qeStepVoice => 'Transcription terminée sur ton téléphone';

  @override
  String get qeStepText => 'Texte reçu';

  @override
  String get qeStepGemma =>
      'Gemma 4 repère les montants, catégories et comptes…';

  @override
  String get qeSkip => 'Passer';

  @override
  String get qeAiUnavailable => 'Assistant IA indisponible.';

  @override
  String get qeManageAi => 'Gérer le modèle IA';

  @override
  String get asTitle => 'Copilote';

  @override
  String get asSubtitle => 'Sur ton téléphone · fonctionne hors connexion';

  @override
  String get asFootnote =>
      'Chiffres calculés par l\'application · expliqués par Gemma 4';

  @override
  String get asTyping => 'Analyse de tes opérations…';

  @override
  String get asInputHint => 'Pose ta question…';

  @override
  String get asSend => 'Envoyer';

  @override
  String get asIntro =>
      'Pose une question sur tes dépenses, tes budgets, tes soldes ou un achat. Les chiffres sont toujours calculés par l\'application.';

  @override
  String get asSuggest2 => 'Quelle catégorie me coûte le plus ?';

  @override
  String get asSuggest3 => 'Combien puis-je dépenser cette semaine ?';

  @override
  String get asSuggest5 => 'Puis-je acheter un téléphone à 150 000 ?';

  @override
  String get asFallback =>
      'Je n\'ai pas bien compris. Tu peux me demander « Mes dépenses cette semaine » ou « Combien puis-je dépenser cette semaine ? ».';

  @override
  String get asError => 'Je n\'ai pas pu répondre. Réessaie.';

  @override
  String get asOffTitle => 'L\'assistant n\'est pas chargé';

  @override
  String get asOffBody =>
      'Les questions en langage naturel sont indisponibles pour l\'instant. Tous tes chiffres restent accessibles.';

  @override
  String get asOffNotInstalled =>
      'L\'assistant n\'est pas installé. Tous tes chiffres restent accessibles.';

  @override
  String get asOffUnavailable =>
      'L\'assistant IA n\'est pas disponible sur ce téléphone. Tous tes chiffres restent accessibles.';

  @override
  String get asOffDownloading =>
      'Téléchargement de l\'assistant en cours. Tous tes chiffres restent accessibles.';

  @override
  String get asLoad => 'Charger l\'assistant';

  @override
  String get asInstall => 'Installer l\'assistant';

  @override
  String get asLoading => 'Chargement de l\'assistant…';

  @override
  String get asShortcutDictate => 'Dicter';

  @override
  String get asLinkTransactions => 'Voir les opérations';

  @override
  String get asLinkBudgets => 'Voir mes budgets';

  @override
  String get asLinkAccounts => 'Voir mes comptes';

  @override
  String get asLinkForecast => 'Voir la prévision';

  @override
  String get asLinkSimulation => 'Ouvrir la simulation';

  @override
  String get asPeriodToday => 'aujourd\'hui';

  @override
  String get asPeriodWeek => 'cette semaine';

  @override
  String get asPeriodMonth => 'ce mois-ci';

  @override
  String get asPeriodLastMonth => 'le mois dernier';

  @override
  String asSpending(String amount, String period) {
    return 'Tu as dépensé $amount FCFA $period.';
  }

  @override
  String asSpendingCategory(String amount, String category, String period) {
    return 'Tu as dépensé $amount FCFA en $category $period.';
  }

  @override
  String asSpendingTop(String category, String amount, String percent) {
    return 'Ta plus grosse dépense : $category, $amount FCFA ($percent %).';
  }

  @override
  String asSpendingNone(String period) {
    return 'Aucune dépense enregistrée $period.';
  }

  @override
  String get asNoBudget =>
      'Tu n\'as pas encore de budget. Crée-en un pour savoir combien tu peux dépenser.';

  @override
  String asNoBudgetCategory(String category) {
    return 'Tu n\'as pas de budget pour $category.';
  }

  @override
  String asBudget(String week, String perDay) {
    return 'Pour rester dans tes budgets, tu peux dépenser environ $week FCFA sur les 7 prochains jours, soit $perDay FCFA par jour.';
  }

  @override
  String asBudgetCategory(String category, String remaining, String limit) {
    return 'Budget $category : il te reste $remaining FCFA sur $limit FCFA.';
  }

  @override
  String asBudgetExceeded(String amount) {
    return 'Tes budgets sont dépassés de $amount FCFA ce mois-ci.';
  }

  @override
  String asBudgetCategoryExceeded(String category, String amount) {
    return 'Le budget $category est dépassé de $amount FCFA.';
  }

  @override
  String asRowRemaining(String month) {
    return 'Reste du budget de $month';
  }

  @override
  String get asRowDaysLeft => 'Jours restants';

  @override
  String get asRowWeek => 'Possible sur 7 jours';

  @override
  String asRowSpentOf(String spent, String limit) {
    return '$spent sur $limit FCFA';
  }

  @override
  String asBalance(String amount) {
    return 'Tu as $amount FCFA sur tes comptes.';
  }

  @override
  String asBalanceAccount(String amount, String account) {
    return 'Tu as $amount FCFA sur $account.';
  }

  @override
  String get asRowTotal => 'Total';

  @override
  String asForecast(String amount, String date, String level) {
    return 'Ton solde devrait être d\'environ $amount FCFA le $date. Fiabilité $level : c\'est une estimation, pas une certitude.';
  }

  @override
  String asForecastNegative(String date) {
    return 'Attention : ton solde passerait sous zéro vers le $date.';
  }

  @override
  String get asForecastTooEarly =>
      'Les prévisions apparaîtront après environ deux semaines d\'opérations.';

  @override
  String asRowForecastOn(String date) {
    return 'Solde prévu le $date';
  }

  @override
  String get asRowRange => 'Fourchette probable';

  @override
  String asRowRangeValue(String low, String high) {
    return '$low à $high FCFA';
  }

  @override
  String get asRowReliability => 'Fiabilité';

  @override
  String asSimPossible(String lowest, String date) {
    return 'C\'est possible : ton disponible le plus bas serait d\'environ $lowest FCFA, le $date.';
  }

  @override
  String asSimTight(String lowest, String date) {
    return 'C\'est possible, mais serré : ton disponible descendrait à environ $lowest FCFA le $date.';
  }

  @override
  String asSimDiscouraged(String date) {
    return 'Pas maintenant : ton disponible passerait sous zéro vers le $date.';
  }

  @override
  String get asRowLowest => 'Disponible le plus bas';

  @override
  String asRowEndWith(String date) {
    return 'Le $date, avec l\'achat';
  }

  @override
  String asRowEndWithout(String date) {
    return 'Le $date, sans l\'achat';
  }

  @override
  String get asSuggestSave => 'Pourquoi j\'ai du mal à économiser ?';

  @override
  String get asSuggestGoal => 'Comment économiser 100 000 en 3 mois ?';

  @override
  String get asPrepared =>
      'J\'ai préparé cette opération. Vérifie avant d\'enregistrer :';

  @override
  String asPreparedMany(int count) {
    return 'J\'ai préparé ces $count opérations. Vérifie avant d\'enregistrer :';
  }

  @override
  String get asPreparedNone =>
      'Je n\'ai pas trouvé de montant. Écris par exemple « Taxi 2 500 avec Wave ».';

  @override
  String asSavePrepared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Enregistrer les $count opérations',
      one: 'Enregistrer',
    );
    return '$_temp0';
  }

  @override
  String get asEditPrepared => 'Modifier';

  @override
  String asSavedOne(String kind, String account, String balance) {
    return '$kind enregistrée · solde $account : $balance FCFA';
  }

  @override
  String asSavedMany(int count) {
    return '$count opérations enregistrées';
  }

  @override
  String get asSaveFailed =>
      'L\'enregistrement a échoué. Touche « Modifier » pour vérifier l\'opération.';

  @override
  String get asNotSaved => 'Non enregistrée';

  @override
  String get asRowAmount => 'Montant';

  @override
  String get asRowCategory => 'Catégorie';

  @override
  String get asRowAccount => 'Compte';

  @override
  String get asRowDate => 'Date';

  @override
  String get asSavingsTooEarly =>
      'Il faut environ un mois d\'opérations pour faire ce bilan.';

  @override
  String asSavings(String income, String expenses, String percent) {
    return 'En moyenne, tu gagnes $income FCFA et tu dépenses $expenses FCFA par mois. Tes charges fixes en représentent $percent %.';
  }

  @override
  String asSavingsDeficit(String expenses, String income, String percent) {
    return 'En moyenne, tes dépenses ($expenses FCFA) dépassent tes revenus ($income FCFA) chaque mois. Tes charges fixes en représentent $percent %.';
  }

  @override
  String get asRowIncome => 'Revenus moyens';

  @override
  String get asRowExpenses => 'Dépenses moyennes';

  @override
  String get asRowFixed => 'Dont charges fixes';

  @override
  String asGoalFeasible(String monthly, String surplus) {
    return 'C\'est faisable : il faut mettre de côté environ $monthly FCFA par mois, et tu épargnes en moyenne $surplus FCFA par mois.';
  }

  @override
  String asGoalHard(String monthly, String surplus) {
    return 'Il faudrait mettre de côté $monthly FCFA par mois, plus que ton épargne moyenne actuelle ($surplus FCFA). Un délai plus long ou moins de dépenses aideraient.';
  }

  @override
  String asGoalUnknown(String monthly) {
    return 'Il faut mettre de côté environ $monthly FCFA par mois.';
  }

  @override
  String get asRowMonthly => 'À mettre de côté par mois';

  @override
  String get asRowSurplus => 'Ton épargne moyenne actuelle';

  @override
  String get asRowDeadline => 'Échéance';

  @override
  String get asLinkGoal => 'Créer l\'objectif';

  @override
  String get simAskCopilot => 'En parler au Copilote';

  @override
  String simAskQuestion(String label, String price) {
    return 'Puis-je acheter $label à $price FCFA ?';
  }

  @override
  String simAskQuestionNoLabel(String price) {
    return 'Puis-je faire un achat de $price FCFA ?';
  }

  @override
  String goalDueMonths(int count) {
    return '$count mois';
  }

  @override
  String get settingsClearHistory => 'Effacer l\'historique de conversation';

  @override
  String get settingsClearHistoryTitle => 'Effacer l\'historique ?';

  @override
  String get settingsClearHistoryBody =>
      'Toutes tes conversations avec le Copilote seront supprimées. Tes opérations, budgets et objectifs ne changent pas.';

  @override
  String get settingsClearHistoryConfirm => 'Effacer';

  @override
  String get settingsHistoryCleared => 'Historique effacé.';

  @override
  String get ntChannelReminders => 'Rappels d\'échéance';

  @override
  String get ntChannelRemindersHint =>
      'Le jour d\'une opération récurrente, à 9 h';

  @override
  String get ntChannelBudgets => 'Alertes de budget';

  @override
  String get ntChannelBudgetsHint => 'Au seuil d\'alerte et au dépassement';

  @override
  String get ntChannelLowBalance => 'Solde bas';

  @override
  String get ntChannelLowBalanceHint => '3 jours avant un solde bas possible';

  @override
  String ntReminderTitle(String name, String amount) {
    return '$name · $amount FCFA aujourd\'hui';
  }

  @override
  String get ntReminderConfirm => 'Touche pour l\'enregistrer.';

  @override
  String get ntReminderAuto =>
      'Elle sera enregistrée à l\'ouverture de l\'application.';

  @override
  String ntBudgetWarningTitle(String category, String percent) {
    return '$category : $percent % du budget utilisé';
  }

  @override
  String ntBudgetWarningBody(String remaining) {
    return 'Il te reste $remaining FCFA jusqu\'à la fin du mois.';
  }

  @override
  String ntBudgetReachedTitle(String category) {
    return '$category : budget atteint';
  }

  @override
  String ntBudgetExceededTitle(String category, String amount) {
    return '$category : budget dépassé de $amount FCFA';
  }

  @override
  String get ntBudgetBody => 'Touche pour voir tes budgets.';

  @override
  String ntLowBalanceTitle(String date) {
    return 'Solde bas possible le $date';
  }

  @override
  String ntLowBalanceBody(String amount) {
    return '≈ $amount FCFA prévus. C\'est une estimation : touche pour voir la prévision.';
  }

  @override
  String get settingsNotifSection => 'Notifications';

  @override
  String get dashboardShowAmounts => 'Afficher les montants';

  @override
  String get dashboardHideAmounts => 'Masquer les montants';

  @override
  String get settingsLocalOnly =>
      'Données stockées uniquement sur ce téléphone';

  @override
  String get settingsPrefsSection => 'Préférences';

  @override
  String get settingsCurrency => 'Devise';

  @override
  String get settingsCurrencyValue => 'FCFA (XOF)';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageValue => 'Français';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeSystem => 'Automatique';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsRecurring => 'Opérations récurrentes';

  @override
  String settingsRecurringCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actives',
      one: '1 active',
      zero: 'Aucune active',
    );
    return '$_temp0';
  }

  @override
  String get settingsHideAmounts => 'Masquer les montants à l\'ouverture';

  @override
  String get settingsHideAmountsHint =>
      'Sur l\'accueil, touche l\'œil pour les afficher';

  @override
  String get settingsSecuritySection => 'Sécurité et confidentialité';

  @override
  String get settingsPrivacy => 'Confidentialité';

  @override
  String get settingsPrivacyHint =>
      'Aucune donnée n\'est envoyée sur Internet, sauf le téléchargement du modèle IA si tu l\'installes.';

  @override
  String settingsFooter(String app, String version) {
    return '$app $version · données stockées localement';
  }

  @override
  String get lockEnter => 'Saisis ton code';

  @override
  String lockWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Code incorrect. Encore $count essais.',
      one: 'Code incorrect. Encore 1 essai.',
    );
    return '$_temp0';
  }

  @override
  String lockWait(String time) {
    return 'Trop d\'essais. Réessaie dans $time.';
  }

  @override
  String get lockBiometricReason => 'Déverrouiller Finao';

  @override
  String get lockBiometricButton => 'Empreinte ou visage';

  @override
  String get lockDelete => 'Effacer';

  @override
  String get lockForgot => 'Code oublié ?';

  @override
  String get lockForgotTitle => 'Code oublié';

  @override
  String get lockForgotBody =>
      'Sans serveur, le code ne peut pas être récupéré. Si tu as activé l\'empreinte ou le visage, utilise-les. Sinon, la seule solution est d\'effacer les données de l\'application dans les réglages d\'Android : toutes tes opérations seront perdues.';

  @override
  String get lockForgotOk => 'Compris';

  @override
  String get pinCreateTitle => 'Choisis un code';

  @override
  String get pinCreateHint =>
      '4 chiffres, demandés à l\'ouverture de l\'application.';

  @override
  String get pinCreateWarning =>
      'Retiens-le bien : sans serveur, un code oublié ne peut pas être récupéré. Active aussi l\'empreinte ou le visage si ton téléphone le permet.';

  @override
  String get pinConfirmTitle => 'Confirme ton code';

  @override
  String get pinMismatch => 'Les deux codes ne correspondent pas. Recommence.';

  @override
  String get pinCurrentTitle => 'Code actuel';

  @override
  String get pinNewTitle => 'Nouveau code';

  @override
  String get pinChanged => 'Code modifié.';

  @override
  String get pinEnabled => 'Verrouillage activé.';

  @override
  String get pinDisabled => 'Verrouillage désactivé.';

  @override
  String get settingsLock => 'Verrouillage de l\'application';

  @override
  String get settingsLockHint => 'Demandé à chaque ouverture';

  @override
  String get settingsPin => 'Code PIN';

  @override
  String get settingsPinChange => 'Modifier';

  @override
  String get settingsBiometric => 'Biométrie (facultatif)';

  @override
  String get settingsBiometricHint => 'Empreinte ou visage à la place du code';

  @override
  String get settingsBiometricFailed => 'Empreinte ou visage non reconnu.';

  @override
  String get settingsLockDelay => 'Verrouiller après';

  @override
  String get lockDelayImmediately => 'Immédiatement';

  @override
  String get lockDelayOneMinute => '1 minute';

  @override
  String get lockDelayFiveMinutes => '5 minutes';

  @override
  String get bkSection => 'Sauvegarde et données';

  @override
  String get bkBackup => 'Sauvegarde';

  @override
  String get bkNever => 'Aucune sauvegarde pour l\'instant';

  @override
  String bkLast(String day, String time, String size) {
    return '$day à $time · $size, chiffrée';
  }

  @override
  String get bkSaving => 'Sauvegarde en cours…';

  @override
  String get bkRestoring => 'Restauration en cours…';

  @override
  String get bkFailedStorage =>
      'La sauvegarde a échoué. Espace de stockage insuffisant. Libère de l\'espace puis réessaie.';

  @override
  String get bkFailedOther => 'La sauvegarde a échoué. Réessaie.';

  @override
  String get bkRetry => 'Réessayer';

  @override
  String get bkDone => 'Sauvegarde terminée.';

  @override
  String get bkRestore => 'Restaurer une sauvegarde';

  @override
  String get bkRestoreHint => 'Fichier .finao et son mot de passe';

  @override
  String get bkDrive => 'Google Drive';

  @override
  String get bkDriveHint =>
      'Sauvegarde, restauration et synchronisation chiffrées. Facultatif.';

  @override
  String get bkComingSoon => 'À venir';

  @override
  String get bkPasswordTitle => 'Mot de passe de la sauvegarde';

  @override
  String get bkPasswordWarning =>
      'Il protège le fichier. Sans lui, la sauvegarde ne pourra pas être restaurée : il ne peut pas être récupéré.';

  @override
  String get bkPassword => 'Mot de passe';

  @override
  String get bkPasswordConfirm => 'Confirme le mot de passe';

  @override
  String get bkPasswordTooShort => 'Au moins 8 caractères.';

  @override
  String get bkPasswordMismatch =>
      'Les deux mots de passe ne correspondent pas.';

  @override
  String get bkPasswordShow => 'Afficher le mot de passe';

  @override
  String get bkSave => 'Sauvegarder';

  @override
  String get bkContinue => 'Continuer';

  @override
  String get bkCancel => 'Annuler';

  @override
  String get bkUnreadable =>
      'Mot de passe incorrect, ou ce fichier n\'est pas une sauvegarde.';

  @override
  String get bkTooNew =>
      'Cette sauvegarde vient d\'une version plus récente de l\'application. Mets l\'application à jour puis réessaie.';

  @override
  String bkConfirmTitle(String day) {
    return 'Restaurer la sauvegarde du $day ?';
  }

  @override
  String bkConfirmBody(String day, String time) {
    return 'Tes données actuelles seront remplacées par celles du $day à $time. Les opérations saisies depuis seront perdues.';
  }

  @override
  String get bkConfirm => 'Restaurer';

  @override
  String get bkRestored => 'Sauvegarde restaurée.';

  @override
  String get bkRestoreFailed =>
      'La restauration a échoué. Tes données actuelles n\'ont pas changé.';

  @override
  String get exExport => 'Exporter mes données';

  @override
  String get exExportHint => 'CSV, PDF';

  @override
  String get exTitle => 'Exporter';

  @override
  String get exWarning =>
      'Le fichier exporté n\'est pas chiffré : toute personne qui l\'ouvre voit tes opérations. Partage-le avec prudence.';

  @override
  String get exCsv => 'Toutes les opérations (CSV)';

  @override
  String get exCsvHint => 'Pour Excel ou Google Sheets';

  @override
  String get exPdf => 'Relevé du mois (PDF)';

  @override
  String get exPdfHint => 'Totaux, répartition et opérations';

  @override
  String get exMonth => 'Mois';

  @override
  String get exShare => 'Partager';

  @override
  String get exSave => 'Enregistrer';

  @override
  String get exSaved => 'Fichier enregistré.';

  @override
  String get exFailed => 'L\'export a échoué. Réessaie.';

  @override
  String get exEmpty => 'Aucune opération à exporter.';

  @override
  String get exCsvDate => 'Date';

  @override
  String get exCsvKind => 'Type';

  @override
  String get exCsvAmount => 'Montant (FCFA)';

  @override
  String get exCsvCategory => 'Catégorie';

  @override
  String get exCsvSubcategory => 'Sous-catégorie';

  @override
  String get exCsvAccount => 'Compte';

  @override
  String get exCsvToAccount => 'Vers le compte';

  @override
  String get exCsvDescription => 'Description';

  @override
  String get exCsvEntry => 'Saisie';

  @override
  String exPdfTitle(String month) {
    return 'Relevé de $month';
  }

  @override
  String exPdfGenerated(String date) {
    return 'Généré le $date · données de ce téléphone';
  }

  @override
  String get exPdfIncome => 'Revenus';

  @override
  String get exPdfExpenses => 'Dépenses';

  @override
  String get exPdfNet => 'Solde du mois';

  @override
  String get exPdfBreakdown => 'Répartition des dépenses';

  @override
  String exPdfOperations(int count) {
    return 'Opérations ($count)';
  }

  @override
  String get exPdfTransfersNote =>
      'Transferts entre tes comptes exclus des totaux.';

  @override
  String get exPdfOthers => 'Autres';

  @override
  String get ntChannelBackup => 'Rappel de sauvegarde';

  @override
  String get ntChannelBackupHint => 'Un mois après la dernière sauvegarde';

  @override
  String get ntBackupTitle => 'Pense à sauvegarder tes données';

  @override
  String ntBackupBodyLast(String date) {
    return 'Ta dernière sauvegarde date du $date.';
  }

  @override
  String get ntBackupBodyNever =>
      'Tu n\'as encore jamais sauvegardé tes opérations.';

  @override
  String get settingsMonthStart => 'Début du mois budgétaire';

  @override
  String get settingsMonthStartHint => 'Budgets et totaux du mois';

  @override
  String get settingsMonthStartFirst => 'Le 1er';

  @override
  String settingsMonthStartDay(int day) {
    return 'Le $day';
  }

  @override
  String get settingsMonthStartExplain =>
      'Par exemple le 25 si ton salaire arrive le 25 : ton mois va alors du 25 au 24 du mois suivant. Les prévisions, échéances et objectifs gardent leurs dates.';

  @override
  String inBudgetExceeded(String category, String amount) {
    return 'Ton budget $category est dépassé de $amount FCFA.';
  }

  @override
  String inBudgetExceededDriver(
    String category,
    String amount,
    String driver,
    String count,
  ) {
    return 'Ton budget $category est dépassé de $amount FCFA, surtout à cause de $driver ($count opérations).';
  }

  @override
  String inBudgetExceededGlobal(String amount) {
    return 'Ton budget du mois est dépassé de $amount FCFA.';
  }

  @override
  String inBudgetWarning(
    String category,
    String percent,
    String remaining,
    String days,
  ) {
    return 'Ton budget $category est utilisé à $percent % : il te reste $remaining FCFA pour $days jours.';
  }

  @override
  String inBudgetWarningGlobal(String percent, String remaining, String days) {
    return 'Ton budget du mois est utilisé à $percent % : il te reste $remaining FCFA pour $days jours.';
  }

  @override
  String inLowBalance(String date, String amount) {
    return 'Solde bas possible le $date (≈ $amount FCFA).';
  }

  @override
  String inLowBalanceBeforeIncome(String date, String amount) {
    return 'Solde bas possible le $date (≈ $amount FCFA), juste avant ton salaire.';
  }

  @override
  String inPending(String name, String amount) {
    return '$name ($amount FCFA) attend ta confirmation.';
  }

  @override
  String inSpendingUp(String percent, String current, String previous) {
    return 'Tu as dépensé $percent % de plus que le mois dernier à la même date : $current FCFA contre $previous FCFA.';
  }

  @override
  String inAskBudget(String category) {
    return 'Pourquoi mon budget $category est dépassé ?';
  }

  @override
  String get inAskBudgetGlobal => 'Pourquoi mon budget du mois est dépassé ?';

  @override
  String get inAskSpend => 'Combien puis-je dépenser cette semaine ?';

  @override
  String get inAskForecast => 'Mon solde à la fin du mois ?';

  @override
  String get inAskSpendingUp => 'Quelle catégorie me coûte le plus ?';

  @override
  String get inAskCopilot => 'Demander au Copilote';

  @override
  String get inSeePending => 'Voir l\'échéance';

  @override
  String get homeForecastTitle => 'Dans 30 jours';

  @override
  String homeForecastRange(String low, String high) {
    return 'Probablement entre $low et $high FCFA';
  }

  @override
  String get homeForecastLink => 'Comprendre cette prévision';

  @override
  String get settingsSuggestions => 'Suggestions du Copilote';

  @override
  String get settingsSuggestionsHint => 'Phrases factuelles sur l\'accueil';

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

  @override
  String get txModePaid => 'Payée';

  @override
  String get txModePlanned => 'Planifiée';

  @override
  String get txModePaidHint =>
      'Déjà payée : elle sort de ton compte à la date choisie.';

  @override
  String get txModePlannedHint =>
      'À payer plus tard : rien ne sort de ton compte aujourd\'hui.';

  @override
  String get plannedName => 'Libellé';

  @override
  String get plannedNameHint =>
      'Donne un nom à cette dépense pour la retrouver.';

  @override
  String get plannedNameHintExample => 'Par exemple : Scolarité';

  @override
  String get plannedDueDate => 'Date prévue de paiement';

  @override
  String get plannedDuePickerHelp => 'Date prévue';

  @override
  String plannedInfoSameMonth(Object month) {
    return 'Comptée dans les dépenses de $month. Ton solde actuel ne change pas tant que tu ne la marques pas payée.';
  }

  @override
  String plannedInfoLaterMonth(Object current, Object month) {
    return 'Comptée dans les dépenses de $month, pas en $current. Ton solde actuel ne change pas tant que tu ne la marques pas payée.';
  }

  @override
  String get plannedNote => 'Note (facultative)';

  @override
  String get plannedAddNote => 'Ajouter une note';

  @override
  String get plannedSave => 'Planifier la dépense';

  @override
  String get plannedSavedHeading => 'Dépense planifiée';

  @override
  String plannedSavedTitle(Object name) {
    return '« $name » planifiée';
  }

  @override
  String plannedSavedMeta(Object account, Object category, Object date) {
    return '$category · $account · à payer le $date';
  }

  @override
  String get plannedSeeExpense => 'Voir la dépense';

  @override
  String get plannedEditTitle => 'Modifier la dépense planifiée';

  @override
  String get plannedUpdated => 'Dépense planifiée modifiée.';

  @override
  String get plannedTitle => 'Dépense planifiée';

  @override
  String get plannedNotFound => 'Cette dépense planifiée n\'existe plus.';

  @override
  String get plannedStatusPlanned => 'Planifiée';

  @override
  String get plannedStatusLate => 'En retard';

  @override
  String get plannedStatusPaid => 'Payée';

  @override
  String get plannedStatusPaidEarly => 'Payée en avance';

  @override
  String get plannedDue => 'Date prévue';

  @override
  String get plannedPaidOn => 'Payée le';

  @override
  String get plannedNotYet => 'Pas encore';

  @override
  String get plannedCreated => 'Créée le';

  @override
  String get plannedNoteRow => 'Note';

  @override
  String plannedImpactPlannedTitle(Object month) {
    return 'Comptée en $month, pas avant';
  }

  @override
  String plannedImpactPlannedText(Object date, Object month) {
    return 'Elle s\'ajoute aux dépenses planifiées de $month et à ta prévision, à la date du $date. Ton solde réel ne change pas tant qu\'elle n\'est pas payée.';
  }

  @override
  String get plannedImpactLateTitle => 'Toujours à payer';

  @override
  String plannedImpactLateText(Object month) {
    return 'La date prévue est passée. Elle reste dans les dépenses planifiées de $month et dans tes prévisions, mais elle n\'est pas comptée comme payée.';
  }

  @override
  String get plannedMarkPaid => 'Marquer comme payée';

  @override
  String get plannedPayDate => 'Date réelle du paiement';

  @override
  String plannedPayToday(Object date) {
    return 'Aujourd\'hui · $date';
  }

  @override
  String plannedPayYesterday(Object date) {
    return 'Hier · $date';
  }

  @override
  String plannedPayOnDue(Object date) {
    return 'À la date prévue · $date';
  }

  @override
  String get plannedPaidFrom => 'Payée depuis';

  @override
  String plannedPaidFromValue(Object account, Object amount) {
    return '$account · $amount FCFA';
  }

  @override
  String get plannedPayEarlyTitle => 'Paiement anticipé.';

  @override
  String plannedPayEarlyText(
    Object due,
    Object dueMonth,
    Object paid,
    Object paidMonth,
  ) {
    return 'Prévue le $due, payée le $paid : elle comptera dans les dépenses réelles de $paidMonth et sortira des prévisions de $dueMonth. La date prévue reste dans l\'historique.';
  }

  @override
  String plannedPayLateText(Object date) {
    return 'Payée après la date prévue : elle comptera à sa date réelle, le $date.';
  }

  @override
  String get plannedPayConfirm => 'Confirmer le paiement';

  @override
  String plannedPaidToast(Object account, Object amount, Object name) {
    return '$name payée · −$amount FCFA sur $account';
  }

  @override
  String plannedDeleteTitle(Object name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String plannedDeleteBody(Object month) {
    return 'Elle sort des dépenses planifiées de $month et de tes prévisions. Aucun argent n\'a bougé : ton solde ne change pas.';
  }

  @override
  String get plannedDeletedTitle => 'Dépense planifiée supprimée';

  @override
  String plannedDeletedBody(Object month, Object name) {
    return '« $name » ne compte plus dans les dépenses de $month ni dans tes prévisions. Aucun argent n\'a bougé.';
  }

  @override
  String get plannedDueMissingFuture =>
      'Choisis une date après aujourd\'hui. Pour une dépense déjà faite, choisis « Payée ».';

  @override
  String get plannedLateGroup => 'En retard';

  @override
  String get plannedUpcomingGroup => 'À venir';

  @override
  String plannedGroupTotal(Object amount) {
    return '$amount à payer';
  }

  @override
  String plannedLateMeta(Object account, Object date) {
    return 'Prévue le $date · $account';
  }

  @override
  String plannedUpcomingMeta(Object account, Object date) {
    return '$date · $account';
  }

  @override
  String get txPlannedDue => 'Date prévue';

  @override
  String get txDeletePlannedNote =>
      'La dépense planifiée qu\'elle a payée sera supprimée aussi.';

  @override
  String get forecastHowPlanned =>
      'Tes dépenses planifiées sont comptées à leur date prévue ; celles en retard, dès demain.';

  @override
  String ntPlannedTitle(Object amount, Object name) {
    return '$name · $amount FCFA à payer aujourd\'hui';
  }

  @override
  String get ntPlannedBody =>
      'Dépense planifiée : marque-la payée une fois réglée.';

  @override
  String get calTitle => 'Calendrier';

  @override
  String get calSeeMonth => 'Voir tout le mois';

  @override
  String get calCollapse => 'Réduire';

  @override
  String get calPrevMonth => 'Mois précédent';

  @override
  String get calNextMonth => 'Mois suivant';

  @override
  String get calLegendPaid => 'Payées, selon le montant';

  @override
  String get calLegendPlanned => 'Planifiée';

  @override
  String get calLegendLate => 'En retard';

  @override
  String calDayToday(Object day) {
    return '$day · aujourd\'hui';
  }

  @override
  String calDaySpent(Object amount) {
    return '$amount FCFA dépensés';
  }

  @override
  String calDayDue(Object amount) {
    return '$amount FCFA à payer';
  }

  @override
  String calDayLate(Object amount) {
    return '$amount FCFA en retard';
  }

  @override
  String calDayEmptyMonth(Object month) {
    return 'Aucune dépense enregistrée en $month.';
  }

  @override
  String get calDayEmptyFuture => 'Rien de prévu ce jour-là.';

  @override
  String get calDayEmpty => 'Aucune dépense ce jour-là.';

  @override
  String get calPlanThisDay => 'Planifier une dépense ce jour-là';

  @override
  String calDaySemantics(Object day, Object details) {
    return '$day$details';
  }

  @override
  String calDaySpentShort(Object amount) {
    return ', $amount FCFA dépensés';
  }

  @override
  String get calDayPlannedShort => ', dépense à payer';

  @override
  String get calDayLateShort => ', dépense en retard';

  @override
  String spendTitle(Object month) {
    return 'Dépenses de $month';
  }

  @override
  String get spendPaid => 'Payées';

  @override
  String get spendPlanned => 'Planifiées';

  @override
  String get spendTotal => 'Total prévu';

  @override
  String get spendNoteFuture =>
      'Rien n\'est encore payé : ces dépenses ne touchent pas ton solde actuel.';

  @override
  String get spendNoteCurrent =>
      'Total prévu = payées + planifiées encore à payer.';

  @override
  String spendNoteCurrentLate(Object amount) {
    return 'Total prévu = payées + planifiées encore à payer, dont $amount FCFA en retard.';
  }

  @override
  String get spendNoteEmpty => 'Aucune dépense ce mois-là.';

  @override
  String get spendNotePast =>
      'Mois terminé : tout ce qui était prévu a été payé.';

  @override
  String spendNotePastLate(Object amount) {
    return 'Mois terminé : $amount FCFA restent à payer.';
  }

  @override
  String spendSeeMonth(Object month) {
    return 'Voir les dépenses de $month';
  }

  @override
  String get monthPageTitle => 'Dépenses du mois';

  @override
  String get monthTotalLabel => 'Total prévu des dépenses';

  @override
  String monthLateTitle(Object amount) {
    return 'En retard · $amount FCFA';
  }

  @override
  String monthPlanTitle(Object amount) {
    return 'À payer · $amount FCFA';
  }

  @override
  String monthPaidTitle(Object amount) {
    return 'Payées · $amount FCFA';
  }

  @override
  String get monthSeeOperations => 'Voir les opérations';

  @override
  String monthEmptyTitle(Object month) {
    return 'Aucune dépense en $month';
  }

  @override
  String get monthEmptyText => 'Rien de payé ni de planifié ce mois-là.';

  @override
  String get monthRule =>
      'Une dépense planifiée compte dans le mois de sa date prévue. Payée en avance, elle passe dans le mois de son paiement réel et quitte les planifiées : jamais comptée deux fois.';

  @override
  String dueRecurringMeta(Object account, Object date) {
    return '$date · récurrente · $account';
  }

  @override
  String dueRecurringLateMeta(Object account, Object date) {
    return 'Prévue le $date · récurrente · $account';
  }

  @override
  String get plannedRealBalance => 'Solde réel aujourd\'hui';

  @override
  String get txSpanDay => 'Jour';

  @override
  String get txSpanWeek => 'Semaine';

  @override
  String get txSpanMonth => 'Mois';

  @override
  String get txSpanCustom => 'Période';

  @override
  String txPeriodRange(Object end, Object start) {
    return '$start – $end';
  }

  @override
  String get txPrevPeriod => 'Période précédente';

  @override
  String get txNextPeriod => 'Période suivante';

  @override
  String txChoosePeriod(Object period) {
    return 'Choisir la période, actuellement $period';
  }

  @override
  String get txSumPaid => 'Payées';

  @override
  String get txSumPlanned => 'Planifiées';

  @override
  String get txSumCount => 'Opérations';

  @override
  String txSumNoteIncome(Object amount) {
    return 'Revenus $amount · transferts exclus des totaux';
  }

  @override
  String get txSumNotePlanned =>
      'Les planifiées ne sont pas encore sorties de tes comptes.';

  @override
  String get txStatusAll => 'Tout';

  @override
  String get txStatusPaid => 'Payées';

  @override
  String get txStatusPlanned => 'Planifiées';

  @override
  String txStatusLate(Object count) {
    return 'En retard · $count';
  }

  @override
  String get txFilters => 'Filtres';

  @override
  String txFiltersActive(Object count) {
    return 'Filtres : $count actifs';
  }

  @override
  String get txFiltersReset => 'Réinitialiser';

  @override
  String get txFilterType => 'Type';

  @override
  String get txFilterCategory => 'Catégorie';

  @override
  String get txFilterAccount => 'Compte';

  @override
  String get txFilterAllAccountsShort => 'Tous';

  @override
  String get txFilterAllCategoriesShort => 'Toutes';

  @override
  String txShowCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Voir $count opérations',
      one: 'Voir 1 opération',
      zero: 'Aucune opération',
    );
    return '$_temp0';
  }

  @override
  String txRemoveFilter(Object name) {
    return 'Retirer le filtre $name';
  }

  @override
  String get txNothingTitle => 'Rien sur cette période';

  @override
  String get txNothingFilters =>
      'Aucune opération avec ces filtres sur cette période.';

  @override
  String get txNothingPlanned => 'Aucune dépense planifiée sur cette période.';

  @override
  String txNoResultPeriod(Object query) {
    return 'Aucune opération ne correspond à « $query » sur cette période.';
  }

  @override
  String get txShowAll => 'Tout afficher';

  @override
  String get txEmptyPlan => 'Planifier une dépense';

  @override
  String get txEmptyDictate => 'Dicter';

  @override
  String get txSearchOpen => 'Rechercher';

  @override
  String get txSearchClose => 'Fermer la recherche';

  @override
  String get txRangeTitle => 'Période';

  @override
  String get txRangeFrom => 'Du';

  @override
  String get txRangeTo => 'Au';

  @override
  String get txRangeApply => 'Afficher cette période';

  @override
  String get txRangeLast7 => '7 derniers jours';

  @override
  String get txRangeThisMonth => 'Ce mois-ci';

  @override
  String get txRangeNext30 => '30 prochains jours';

  @override
  String get txRangeLast3Months => '3 derniers mois';

  @override
  String get txLoading => 'Chargement des opérations';

  @override
  String txSwipeDeleted(Object amount, Object title) {
    return 'Opération supprimée : $title · $amount FCFA';
  }

  @override
  String get txSwipeHint => 'Glisser vers la gauche pour supprimer';
}
