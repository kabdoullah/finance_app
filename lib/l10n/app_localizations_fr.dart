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
  String get accountDeleteConfirm => 'Supprimer définitivement';
}
