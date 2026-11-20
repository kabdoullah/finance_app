import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../categories/domain/category.dart';

/// Statut d'une dépense planifiée : payée dès qu'une date réelle existe,
/// sinon en retard si la date prévue est passée.
enum PlannedStatus { planned, late, paid }

/// Dépense à payer plus tard. Elle ne change aucun solde ; elle compte dans
/// les dépenses planifiées du mois de [dueDate] et dans les prévisions.
@immutable
class PlannedExpense {
  const PlannedExpense({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.accountId,
    required this.accountName,
    required this.dueDate,
    required this.createdAt,
    this.parentCategory,
    this.note,
  });

  final String id;
  final String name;
  final Money amount;
  final Category category;
  final Category? parentCategory;
  final String accountId;
  final String accountName;

  /// Date calendaire locale (sans heure).
  final DateTime dueDate;
  final DateTime createdAt;
  final String? note;

  Category get mainCategory => parentCategory ?? category;

  /// Jamais [PlannedStatus.paid] : une dépense payée devient une opération.
  PlannedStatus statusOn(DateTime now) => dueDate.isBefore(CalendarDate.of(now))
      ? PlannedStatus.late
      : PlannedStatus.planned;
}

/// Origine d'une opération créée en payant une dépense planifiée.
@immutable
class PlannedOrigin {
  const PlannedOrigin({
    required this.dueDate,
    required this.createdAt,
    this.note,
  });

  /// Date prévue (calendaire locale) ; la date réelle est celle de
  /// l'opération.
  final DateTime dueDate;
  final DateTime createdAt;
  final String? note;
}
