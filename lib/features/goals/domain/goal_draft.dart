import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';

enum GoalFieldError {
  nameMissing,
  nameTooLong,
  targetMissing,
  targetTooLarge,

  /// La date cible doit être après aujourd'hui (vérifié par le repository).
  dateInPast,
}

enum GoalMovementError {
  amountMissing,

  /// Contribution : plus que le disponible du compte. Retrait : plus que ce
  /// qui est réservé pour l'objectif sur ce compte.
  amountTooLarge,

  /// Compte inexistant ou archivé.
  accountUnavailable,
}

/// Saisie de l'écran « Création d'un objectif ».
@immutable
class GoalDraft {
  const GoalDraft({
    required this.name,
    required this.target,
    required this.iconKey,
    this.targetDate,
  });

  static const maxNameLength = 40;
  static const maxTarget = Money(9999999999);

  final String name;
  final Money target;
  final String iconKey;

  /// `null` = sans date.
  final DateTime? targetDate;

  String get normalizedName => name.trim().replaceAll(RegExp(r'\s+'), ' ');

  Set<GoalFieldError> validate() => {
    if (normalizedName.isEmpty) GoalFieldError.nameMissing,
    if (normalizedName.length > maxNameLength) GoalFieldError.nameTooLong,
    if (target.value <= 0) GoalFieldError.targetMissing,
    if (target.value > maxTarget.value) GoalFieldError.targetTooLarge,
  };
}
