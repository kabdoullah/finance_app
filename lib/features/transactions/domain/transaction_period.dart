import 'package:flutter/foundation.dart' show immutable;

import '../../../core/time/calendar_date.dart';
import '../../../core/time/month.dart';

/// Pas de la période affichée dans Transactions.
enum PeriodSpan { day, week, month, custom }

/// Période de l'onglet Transactions : un jour, une semaine (lundi →
/// dimanche), un mois budgétaire ou des dates choisies. [start] inclus,
/// [end] exclu, minuits locaux.
@immutable
class TransactionPeriod {
  const TransactionPeriod._(this.span, this.start, this.end, [this.month]);

  factory TransactionPeriod.day(DateTime date) {
    final day = CalendarDate.of(date);
    return TransactionPeriod._(PeriodSpan.day, day, _addDays(day, 1));
  }

  factory TransactionPeriod.week(DateTime date) {
    final day = CalendarDate.of(date);
    final monday = _addDays(day, 1 - day.weekday);
    return TransactionPeriod._(PeriodSpan.week, monday, _addDays(monday, 7));
  }

  factory TransactionPeriod.month(Month month) =>
      TransactionPeriod._(PeriodSpan.month, month.start, month.end, month);

  /// Du [first] au [last] inclus (dans n'importe quel ordre).
  factory TransactionPeriod.custom(DateTime first, DateTime last) {
    var a = CalendarDate.of(first), b = CalendarDate.of(last);
    if (b.isBefore(a)) (a, b) = (b, a);
    return TransactionPeriod._(PeriodSpan.custom, a, _addDays(b, 1));
  }

  final PeriodSpan span;
  final DateTime start;
  final DateTime end;

  /// Mois budgétaire d'une période [PeriodSpan.month].
  final Month? month;

  /// Dernier jour inclus.
  DateTime get last => _addDays(end, -1);

  bool contains(DateTime date) {
    final local = date.toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }

  /// Même pas, décalé de [steps] (rien pour une période choisie).
  TransactionPeriod shift(int steps) => switch (span) {
    PeriodSpan.day => TransactionPeriod.day(_addDays(start, steps)),
    PeriodSpan.week => TransactionPeriod.week(_addDays(start, 7 * steps)),
    PeriodSpan.month => TransactionPeriod.month(_shiftMonth(month!, steps)),
    PeriodSpan.custom => this,
  };

  /// Passe au pas [to] autour de [anchor] (aujourd'hui si la période le
  /// contient, sinon son premier jour).
  TransactionPeriod withSpan(
    PeriodSpan to, {
    required DateTime anchor,
    required Month Function(DateTime) monthOf,
  }) => switch (to) {
    PeriodSpan.day => TransactionPeriod.day(anchor),
    PeriodSpan.week => TransactionPeriod.week(anchor),
    PeriodSpan.month => TransactionPeriod.month(monthOf(anchor)),
    PeriodSpan.custom => TransactionPeriod.custom(start, last),
  };

  @override
  bool operator ==(Object other) =>
      other is TransactionPeriod &&
      other.span == span &&
      other.start == start &&
      other.end == end &&
      other.month == month;

  @override
  int get hashCode => Object.hash(span, start, end, month);

  static Month _shiftMonth(Month month, int steps) {
    var shifted = month;
    for (var i = 0; i < steps.abs(); i++) {
      shifted = steps < 0 ? shifted.previous : shifted.next;
    }
    return shifted;
  }

  static DateTime _addDays(DateTime day, int days) =>
      DateTime(day.year, day.month, day.day + days);
}
