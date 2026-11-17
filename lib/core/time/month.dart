import 'package:flutter/foundation.dart';

/// Mois calendaire en heure locale (périodes des listes et des totaux).
@immutable
class Month implements Comparable<Month> {
  const Month(this.year, this.month);

  factory Month.of(DateTime date) {
    final local = date.toLocal();
    return Month(local.year, local.month);
  }

  final int year;

  /// 1 à 12.
  final int month;

  /// Premier instant du mois (inclus).
  DateTime get start => DateTime(year, month);

  /// Premier instant du mois suivant (exclu).
  DateTime get end => DateTime(year, month + 1);

  Month get previous => Month.of(DateTime(year, month - 1));
  Month get next => Month.of(DateTime(year, month + 1));

  bool contains(DateTime date) {
    final local = date.toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }

  @override
  int compareTo(Month other) =>
      year != other.year ? year - other.year : month - other.month;

  @override
  bool operator ==(Object other) =>
      other is Month && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}
