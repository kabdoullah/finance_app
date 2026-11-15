import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_icons.dart';
import '../../../l10n/l10n.dart';
import '../domain/account_type.dart';

/// Opérateurs Mobile Money proposés (Côte d'Ivoire).
const mobileMoneyOperators = ['Wave', 'Orange Money', 'MTN MoMo', 'Moov Money'];

/// Ordre des groupes dans « Mes comptes » (maquette).
const accountTypeListOrder = [
  AccountType.mobileMoney,
  AccountType.bank,
  AccountType.cash,
  AccountType.savings,
];

/// Ordre des tuiles du formulaire (maquette).
const accountTypeFormOrder = [
  AccountType.cash,
  AccountType.mobileMoney,
  AccountType.bank,
  AccountType.savings,
];

extension AccountTypeLabels on AccountType {
  String label(AppLocalizations l10n) => switch (this) {
    AccountType.cash => l10n.accountTypeCash,
    AccountType.mobileMoney => l10n.accountTypeMobileMoney,
    AccountType.bank => l10n.accountTypeBank,
    AccountType.savings => l10n.accountTypeSavings,
  };

  String nameHint(AppLocalizations l10n) => switch (this) {
    AccountType.cash => l10n.accountNameHintCash,
    AccountType.mobileMoney => l10n.accountNameHintMobileMoney,
    AccountType.bank => l10n.accountNameHintBank,
    AccountType.savings => l10n.accountNameHintSavings,
  };

  IconData get icon => switch (this) {
    AccountType.cash => AppIcons.money,
    AccountType.mobileMoney => AppIcons.deviceMobile,
    AccountType.bank => AppIcons.bank,
    AccountType.savings => AppIcons.piggyBank,
  };
}
