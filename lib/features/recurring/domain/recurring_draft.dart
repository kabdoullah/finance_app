import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../../transactions/domain/transaction.dart';
import 'recurrence.dart';

enum RecurringFieldError {
  nameMissing,
  nameTooLong,
  amountMissing,
  amountTooLarge,
  categoryMissing,

  /// Catégorie inexistante ou d'un autre type (vérifié par le repository).
  categoryInvalid,
  accountMissing,

  /// Compte inexistant ou archivé (vérifié par le repository).
  accountUnavailable,
  endBeforeStart,
}

/// Saisie de l'écran « Création d'une opération récurrente ».
@immutable
class RecurringDraft {
  const RecurringDraft({
    required this.kind,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.startDate,
    this.isVariable = false,
    this.categoryId,
    this.accountId,
    this.endDate,
    this.askBeforeRecording = true,
  });

  static const maxNameLength = 80;
  static const maxAmount = Money(999999999);

  final TransactionKind kind;
  final String name;
  final Money amount;
  final bool isVariable;
  final String? categoryId;
  final String? accountId;
  final RecurrenceFrequency frequency;
  final DateTime startDate;

  /// `null` = sans fin.
  final DateTime? endDate;
  final bool askBeforeRecording;

  String get normalizedName => name.trim().replaceAll(RegExp(r'\s+'), ' ');

  Recurrence get recurrence => Recurrence(
    frequency: frequency,
    start: CalendarDate.of(startDate),
    end: endDate == null ? null : CalendarDate.of(endDate!),
  );

  Set<RecurringFieldError> validate() {
    final end = endDate;
    return {
      if (normalizedName.isEmpty) RecurringFieldError.nameMissing,
      if (normalizedName.length > maxNameLength)
        RecurringFieldError.nameTooLong,
      if (amount.value <= 0) RecurringFieldError.amountMissing,
      if (amount.value > maxAmount.value) RecurringFieldError.amountTooLarge,
      if (categoryId == null) RecurringFieldError.categoryMissing,
      if (accountId == null) RecurringFieldError.accountMissing,
      if (end != null &&
          CalendarDate.of(end).isBefore(CalendarDate.of(startDate)))
        RecurringFieldError.endBeforeStart,
    };
  }
}
