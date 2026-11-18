import 'package:intl/intl.dart';

/// Dates courtes des maquettes, en heure locale.
abstract final class AppDateFormat {
  /// « 3 sept. »
  static String dayMonth(DateTime date, String locale) {
    final local = date.toLocal();
    return '${_day(local)} ${DateFormat('MMM', locale).format(local)}';
  }

  /// « 1er sept. 2026 »
  static String dayMonthYear(DateTime date, String locale) {
    final local = date.toLocal();
    return '${_day(local)} ${DateFormat('MMM y', locale).format(local)}';
  }

  /// Une date abrégée finit déjà par un point (« 15 déc. ») : retire le
  /// point doublé en fin de phrase (« d'ici le 15 déc.. »).
  static String sentence(String text) => text.replaceAll('..', '.');

  /// Le premier du mois s'écrit « 1er » en français.
  static String _day(DateTime date) => date.day == 1 ? '1er' : '${date.day}';
}
