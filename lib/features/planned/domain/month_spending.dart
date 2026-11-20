import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/month.dart';
import '../../categories/domain/category.dart';
import '../../recurring/domain/recurring_operation.dart';
import '../../transactions/domain/transaction.dart';
import 'planned_expense.dart';

/// Origine d'une dépense à payer.
enum DueSource { planned, recurring }

/// Dépense encore à payer à une date : dépense planifiée, ou échéance d'une
/// dépense récurrente active (une échéance « à confirmer » passée reste à
/// payer).
@immutable
class DueItem {
  const DueItem({
    required this.source,
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.category,
    required this.accountId,
    required this.accountName,
    this.isEstimate = false,
  });

  DueItem.fromPlanned(PlannedExpense p)
    : this(
        source: DueSource.planned,
        id: p.id,
        name: p.name,
        amount: p.amount,
        date: p.dueDate,
        category: p.mainCategory,
        accountId: p.accountId,
        accountName: p.accountName,
      );

  final DueSource source;

  /// Identifiant de la dépense planifiée ou du modèle récurrent.
  final String id;
  final String name;
  final Money amount;

  /// Date calendaire locale.
  final DateTime date;

  /// Catégorie principale.
  final Category category;
  final String accountId;
  final String accountName;

  /// Montant variable d'une récurrente : c'est une estimation (« ≈ »).
  final bool isEstimate;

  PlannedStatus statusOn(DateTime now) => date.isBefore(CalendarDate.of(now))
      ? PlannedStatus.late
      : PlannedStatus.planned;

  /// Dépenses planifiées et échéances des dépenses récurrentes actives
  /// jusqu'au [until] inclus, par date.
  static List<DueItem> collect({
    required Iterable<PlannedExpense> planned,
    required Iterable<RecurringOperation> recurring,
    required DateTime until,
  }) => [
    for (final p in planned)
      if (!p.dueDate.isAfter(until)) DueItem.fromPlanned(p),
    for (final op in recurring)
      if (op.isActive && op.kind == TransactionKind.expense)
        for (final due in op.recurrence.dueBetween(op.nextDue, until, max: 80))
          DueItem(
            source: DueSource.recurring,
            id: op.id,
            name: op.name,
            amount: op.amount,
            date: due,
            category: op.mainCategory,
            accountId: op.accountId,
            accountName: op.accountName,
            isEstimate: op.isVariable,
          ),
  ]..sort((a, b) => a.date.compareTo(b.date));
}

/// Dépenses d'un mois (budgétaire) : payées au mois de leur paiement réel,
/// à payer au mois de leur date prévue. Jamais comptées deux fois : une
/// dépense payée n'est plus à payer. Transferts exclus.
@immutable
class MonthSpending {
  const MonthSpending._({
    required this.month,
    required this.paid,
    required this.planned,
    required this.late,
    required this.spentByDay,
    required this.dues,
    required this.paidByCategory,
  });

  factory MonthSpending.of({
    required Month month,
    required Iterable<Transaction> transactions,
    required Iterable<DueItem> dues,
    required DateTime now,
  }) {
    final today = CalendarDate.of(now);
    final spentByDay = <DateTime, int>{};
    final byCategory = <String, (Category, int)>{};
    var paid = 0;
    for (final t in transactions) {
      if (t.kind != TransactionKind.expense) continue;
      final local = t.occurredAt.toLocal();
      if (!month.contains(local)) continue;
      paid += t.amount.value;
      final day = CalendarDate.of(local);
      spentByDay[day] = (spentByDay[day] ?? 0) + t.amount.value;
      final category = t.mainCategory;
      if (category != null) {
        final (_, sum) = byCategory[category.id] ?? (category, 0);
        byCategory[category.id] = (category, sum + t.amount.value);
      }
    }
    final inMonth = [
      for (final d in dues)
        if (month.contains(d.date)) d,
    ];
    final planned = inMonth.fold(0, (sum, d) => sum + d.amount.value);
    final late = inMonth
        .where((d) => d.date.isBefore(today))
        .fold(0, (sum, d) => sum + d.amount.value);
    final categories = byCategory.values.toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return MonthSpending._(
      month: month,
      paid: Money(paid),
      planned: Money(planned),
      late: Money(late),
      spentByDay: spentByDay,
      dues: inMonth,
      paidByCategory: [for (final (c, sum) in categories) (c, Money(sum))],
    );
  }

  final Month month;

  /// Dépenses payées dans le mois.
  final Money paid;

  /// Dépenses encore à payer dont la date prévue tombe dans le mois.
  final Money planned;

  /// Part de [planned] dont la date prévue est passée.
  final Money late;

  /// Dépenses payées par jour calendaire local.
  final Map<DateTime, int> spentByDay;

  /// Dépenses à payer du mois, par date.
  final List<DueItem> dues;

  /// Dépenses payées par catégorie principale, de la plus grosse à la plus
  /// petite.
  final List<(Category, Money)> paidByCategory;

  /// Total prévu = payées + à payer.
  Money get total => paid + planned;

  bool get isEmpty => paid.value == 0 && dues.isEmpty;

  List<DueItem> duesOn(DateTime day) => [
    for (final d in dues)
      if (d.date == CalendarDate.of(day)) d,
  ];

  /// Intensité du point d'un jour payé : 0 rien, 1 moins de 5 000, 2 moins
  /// de 20 000, 3 au-delà.
  static int intensity(int spent) => spent <= 0
      ? 0
      : spent < 5000
      ? 1
      : spent < 20000
      ? 2
      : 3;
}
