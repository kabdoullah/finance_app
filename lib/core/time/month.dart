import 'package:flutter/foundation.dart';

/// Mois budgétaire en heure locale (périodes des listes, des totaux et des
/// budgets). Commence le [startDay] (1 à 28, réglage « Début du mois
/// budgétaire ») et porte le nom du mois qui contient le plus de ses jours :
/// début le 1er à 15 → du [startDay] de [month] au [startDay] du mois
/// suivant ; début après le 15 → du [startDay] du mois précédent au
/// [startDay] de [month]. Avec le 1er, c'est le mois calendaire.
@immutable
class Month implements Comparable<Month> {
  const Month(this.year, this.month, {this.startDay = 1})
    : assert(startDay >= 1 && startDay <= maxStartDay);

  /// Mois qui contient [date].
  factory Month.of(DateTime date, {int startDay = 1}) {
    final local = date.toLocal();
    // Mois calendaire où commence la période qui contient [date].
    final startMonth = local.day >= startDay ? local.month : local.month - 1;
    final label = DateTime(
      local.year,
      startDay > _labelShift ? startMonth + 1 : startMonth,
    );
    return Month(label.year, label.month, startDay: startDay);
  }

  /// Au-delà, les mois courts (février) n'auraient pas ce jour.
  static const maxStartDay = 28;

  /// Début après ce jour : le mois porte le nom du mois suivant.
  static const _labelShift = 15;

  final int year;

  /// 1 à 12 : mois qui donne son nom à la période.
  final int month;
  final int startDay;

  int get _startMonth => startDay > _labelShift ? month - 1 : month;

  /// Premier instant de la période (inclus).
  DateTime get start => DateTime(year, _startMonth, startDay);

  /// Premier instant de la période suivante (exclu).
  DateTime get end => DateTime(year, _startMonth + 1, startDay);

  /// Vrai si la période n'est pas le mois calendaire (dates à afficher).
  bool get isShifted => startDay != 1;

  Month get previous {
    final d = DateTime(year, month - 1);
    return Month(d.year, d.month, startDay: startDay);
  }

  Month get next {
    final d = DateTime(year, month + 1);
    return Month(d.year, d.month, startDay: startDay);
  }

  /// Nombre de jours de la période.
  int get length => _days(start, end);

  /// Jours écoulés jusqu'à [now] inclus (1 le premier jour).
  int dayOf(DateTime now) =>
      _days(start, DateTime(now.year, now.month, now.day)) + 1;

  /// Jours restants à partir de [now] inclus (1 le dernier jour).
  int daysLeft(DateTime now) => length - dayOf(now) + 1;

  bool contains(DateTime date) {
    final local = date.toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }

  /// Jours calendaires entre deux minuits locaux (robuste aux changements
  /// d'heure).
  static int _days(DateTime from, DateTime to) =>
      (to.difference(from).inHours / 24).round();

  @override
  int compareTo(Month other) =>
      year != other.year ? year - other.year : month - other.month;

  @override
  bool operator ==(Object other) =>
      other is Month &&
      other.year == year &&
      other.month == month &&
      other.startDay == startDay;

  @override
  int get hashCode => Object.hash(year, month, startDay);

  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}'
      '${startDay == 1 ? '' : '@$startDay'}';
}
