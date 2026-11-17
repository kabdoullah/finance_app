import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';

enum BudgetFieldError {
  limitMissing,
  limitTooLarge,
  alertInvalid,

  /// Catégorie inexistante, sous-catégorie ou catégorie de revenus.
  categoryInvalid,

  /// Cette catégorie (ou le budget global) a déjà un budget.
  alreadyExists,
}

/// Saisie de l'écran « Création d'un budget ».
@immutable
class BudgetDraft {
  const BudgetDraft({
    required this.limit,
    this.categoryId,
    this.alertPercent = defaultAlertPercent,
  });

  static const defaultAlertPercent = 80;
  static const maxLimit = Money(999999999);

  /// `null` = budget global (« Toutes les dépenses »).
  final String? categoryId;
  final Money limit;
  final int alertPercent;

  Set<BudgetFieldError> validate() => {
    if (limit.value <= 0) BudgetFieldError.limitMissing,
    if (limit.value > maxLimit.value) BudgetFieldError.limitTooLarge,
    if (alertPercent < 50 || alertPercent > 100) BudgetFieldError.alertInvalid,
  };
}
