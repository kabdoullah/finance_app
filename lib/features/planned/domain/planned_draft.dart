import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';

enum PlannedFieldError {
  nameMissing,
  nameTooLong,
  amountMissing,
  amountTooLarge,
  categoryMissing,

  /// Catégorie inexistante ou de revenu (vérifié par le repository).
  categoryInvalid,
  accountMissing,

  /// Compte inexistant ou archivé (vérifié par le repository).
  accountUnavailable,

  /// Une dépense planifiée se place après aujourd'hui.
  dueNotInFuture,
  noteTooLong,
}

/// Saisie d'une dépense planifiée (création ou modification).
@immutable
class PlannedDraft {
  const PlannedDraft({
    required this.name,
    required this.amount,
    required this.dueDate,
    this.categoryId,
    this.accountId,
    this.note = '',
  });

  static const maxLength = 80;
  static const maxAmount = Money(999999999);

  static final _spaces = RegExp(r'\s+');

  final String name;
  final Money amount;
  final DateTime dueDate;
  final String? categoryId;
  final String? accountId;
  final String note;

  String get normalizedName => name.trim().replaceAll(_spaces, ' ');

  String? get normalizedNote {
    final text = note.trim().replaceAll(_spaces, ' ');
    return text.isEmpty ? null : text;
  }

  /// [keptDue] : date prévue actuelle d'une dépense modifiée, acceptée telle
  /// quelle même passée (une dépense en retard reste modifiable).
  Set<PlannedFieldError> validate(DateTime now, {DateTime? keptDue}) {
    final due = CalendarDate.of(dueDate);
    final today = CalendarDate.of(now);
    return {
      if (normalizedName.isEmpty) PlannedFieldError.nameMissing,
      if (normalizedName.length > maxLength) PlannedFieldError.nameTooLong,
      if (amount.value <= 0) PlannedFieldError.amountMissing,
      if (amount.value > maxAmount.value) PlannedFieldError.amountTooLarge,
      if (categoryId == null) PlannedFieldError.categoryMissing,
      if (accountId == null) PlannedFieldError.accountMissing,
      if (!due.isAfter(today) && due != keptDue)
        PlannedFieldError.dueNotInFuture,
      if ((normalizedNote?.length ?? 0) > maxLength)
        PlannedFieldError.noteTooLong,
    };
  }
}
