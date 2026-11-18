import 'package:flutter/foundation.dart' show immutable;

/// Fréquence d'une opération récurrente ; l'échéance découle de la date de
/// début (jour de la semaine, jour du mois, ou jour et mois).
enum RecurrenceFrequency {
  week('week'),
  month('month'),
  year('year');

  const RecurrenceFrequency(this.storageValue);

  final String storageValue;

  static RecurrenceFrequency fromStorage(String value) =>
      values.firstWhere((f) => f.storageValue == value);
}

/// Date calendaire locale (sans heure), stockée en « AAAA-MM-JJ ».
abstract final class CalendarDate {
  static DateTime of(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String format(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static DateTime parse(String value) {
    final parts = value.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }
}

/// Calendrier d'échéances : la k-ième échéance est calculée depuis la date
/// de début (jamais d'une échéance à la suivante), pour qu'un 31 redevienne
/// le 31 après un mois court.
@immutable
class Recurrence {
  const Recurrence({required this.frequency, required this.start, this.end});

  final RecurrenceFrequency frequency;

  /// Première échéance (date calendaire).
  final DateTime start;

  /// Dernière date possible ; `null` = sans fin.
  final DateTime? end;

  /// k-ième échéance (k = 0 : la date de début). Un jour 29 à 31 tombe le
  /// dernier jour des mois plus courts.
  DateTime occurrence(int k) => switch (frequency) {
    RecurrenceFrequency.week => DateTime(
      start.year,
      start.month,
      start.day + 7 * k,
    ),
    RecurrenceFrequency.month => _clamped(start.year, start.month + k),
    RecurrenceFrequency.year => _clamped(start.year + k, start.month),
  };

  DateTime _clamped(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = start.day < lastDay ? start.day : lastDay;
    return DateTime(year, month, day);
  }

  /// Première échéance au plus tôt le [date] ; `null` après la fin.
  DateTime? firstOnOrAfter(DateTime date) {
    final day = CalendarDate.of(date);
    var k = day.isAfter(start) ? _indexBefore(day) : 0;
    while (occurrence(k).isBefore(day)) {
      k++;
    }
    return _withinEnd(occurrence(k));
  }

  /// Échéance qui suit [due] ; `null` après la fin.
  DateTime? after(DateTime due) =>
      firstOnOrAfter(DateTime(due.year, due.month, due.day + 1));

  /// Échéances de [from] jusqu'au [until] inclus (au plus [max]).
  List<DateTime> dueBetween(DateTime? from, DateTime until, {int max = 24}) {
    final dates = <DateTime>[];
    var due = from;
    while (due != null && !due.isAfter(until) && dates.length < max) {
      dates.add(due);
      due = after(due);
    }
    return dates;
  }

  /// Nombre total d'échéances ; `null` sans date de fin.
  int? get count {
    final last = end;
    if (last == null) return null;
    var n = 0;
    while (!occurrence(n).isAfter(last)) {
      n++;
    }
    return n;
  }

  /// Estimation basse de l'indice de l'échéance qui précède [date].
  int _indexBefore(DateTime date) {
    final k = switch (frequency) {
      RecurrenceFrequency.week => date.difference(start).inDays ~/ 7,
      RecurrenceFrequency.month =>
        (date.year - start.year) * 12 + date.month - start.month,
      RecurrenceFrequency.year => date.year - start.year,
    };
    return k > 0 ? k - 1 : 0;
  }

  DateTime? _withinEnd(DateTime date) {
    final last = end;
    return last != null && date.isAfter(last) ? null : date;
  }
}
