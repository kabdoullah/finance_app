import 'package:flutter/foundation.dart';

import '../../../core/money/money.dart';
import 'account_type.dart';

/// Compte financier (espèces, Mobile Money, banque, épargne).
@immutable
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.balance,
    required this.createdAt,
    this.archivedAt,
  });

  final String id;
  final String name;
  final AccountType type;

  /// Solde saisi à la création. Ce n'est pas un revenu.
  final Money openingBalance;

  /// Solde actuel, toujours calculé (solde initial + mouvements), jamais saisi.
  final Money balance;

  /// Date de création, qui est aussi la date du solde initial.
  final DateTime createdAt;

  /// Un compte archivé sort des listes et du total ; son historique reste.
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;
}
