import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction.dart';
import 'recurrence.dart';

/// Modèle d'opération récurrente (dépense ou revenu). Ne change aucun solde
/// tant que l'échéance n'est pas enregistrée.
@immutable
class RecurringOperation {
  const RecurringOperation({
    required this.id,
    required this.kind,
    required this.name,
    required this.amount,
    required this.isVariable,
    required this.category,
    required this.accountId,
    required this.accountName,
    required this.recurrence,
    required this.nextDue,
    required this.askBeforeRecording,
    required this.isPaused,
    this.parentCategory,
  });

  final String id;

  /// [TransactionKind.expense] ou [TransactionKind.income].
  final TransactionKind kind;
  final String name;

  /// Montant fixe, ou estimation si [isVariable].
  final Money amount;
  final bool isVariable;
  final Category category;
  final Category? parentCategory;
  final String accountId;
  final String accountName;
  final Recurrence recurrence;

  /// Prochaine échéance non traitée ; `null` si le modèle est terminé.
  final DateTime? nextDue;
  final bool askBeforeRecording;
  final bool isPaused;

  Category get mainCategory => parentCategory ?? category;

  bool get isActive => !isPaused && nextDue != null;

  /// Montant moyen par mois (hebdomadaire ×52÷12, annuel ÷12).
  Money get monthlyAmount => Money(switch (recurrence.frequency) {
    RecurrenceFrequency.week => amount.value * 52 ~/ 12,
    RecurrenceFrequency.month => amount.value,
    RecurrenceFrequency.year => amount.value ~/ 12,
  });

  /// Échéances passées ou du jour, pas encore traitées (modèle actif).
  List<DateTime> dueUntil(DateTime today) => isPaused
      ? const []
      : recurrence.dueBetween(nextDue, CalendarDate.of(today));
}

/// Totaux prévus par mois des modèles actifs (« Revenus prévus / mois »).
@immutable
class RecurringTotals {
  const RecurringTotals._(this.income, this.expense);

  factory RecurringTotals.of(Iterable<RecurringOperation> operations) {
    var income = Money.zero;
    var expense = Money.zero;
    for (final o in operations.where((o) => o.isActive)) {
      if (o.kind == TransactionKind.income) {
        income += o.monthlyAmount;
      } else {
        expense += o.monthlyAmount;
      }
    }
    return RecurringTotals._(income, expense);
  }

  final Money income;
  final Money expense;
}

/// Échéance à confirmer (« À confirmer · échéance hier »).
@immutable
class PendingOccurrence {
  const PendingOccurrence(this.operation, this.due, {required this.isFirst});

  final RecurringOperation operation;
  final DateTime due;

  /// Seule la plus ancienne échéance d'un modèle se traite : les suivantes
  /// attendent leur tour.
  final bool isFirst;

  /// Échéances à confirmer de tous les modèles, de la plus ancienne à la plus
  /// récente.
  static List<PendingOccurrence> of(
    Iterable<RecurringOperation> operations,
    DateTime today,
  ) {
    final pending = [
      for (final o in operations)
        if (o.askBeforeRecording)
          for (final (i, due) in o.dueUntil(today).indexed)
            PendingOccurrence(o, due, isFirst: i == 0),
    ]..sort((a, b) => a.due.compareTo(b.due));
    return pending;
  }
}
