import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../time/month.dart';
import 'date_format.dart';

/// Dates relatives des maquettes (« Aujourd'hui · 15 nov. », « hier à 8:42 »).
class RelativeDate {
  RelativeDate(this.l10n, this.locale, this.now);

  final AppLocalizations l10n;
  final String locale;
  final DateTime now;

  /// 0 = aujourd'hui, 1 = hier… (jours calendaires locaux).
  int _daysAgo(DateTime date) {
    final local = date.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    return today.difference(day).inDays;
  }

  /// « aujourd'hui », « hier » ou « 13 nov. ».
  String day(DateTime date) => switch (_daysAgo(date)) {
    0 => l10n.today,
    1 => l10n.yesterday,
    _ => AppDateFormat.dayMonth(date, locale),
  };

  /// En-tête de groupe : « Aujourd'hui · 15 nov. », « Hier · 14 nov. »,
  /// « Jeudi 13 nov. ».
  String header(DateTime date) {
    final dayMonth = AppDateFormat.dayMonth(date, locale);
    return switch (_daysAgo(date)) {
      0 => l10n.dayHeaderRelative(l10n.dayToday, dayMonth),
      1 => l10n.dayHeaderRelative(l10n.dayYesterday, dayMonth),
      _ => capitalize(
        '${DateFormat('EEEE', locale).format(date.toLocal())} $dayMonth',
      ),
    };
  }

  /// « aujourd'hui à 8:42 », « hier à 8:42 », « 13 nov. à 8:42 ».
  String dayAndTime(DateTime date) =>
      l10n.atTime(day(date), DateFormat('H:mm', locale).format(date.toLocal()));

  /// Ligne de date d'un formulaire : « Aujourd'hui, 15 nov. ».
  String formDate(DateTime date) {
    final dayMonth = AppDateFormat.dayMonth(date, locale);
    return switch (_daysAgo(date)) {
      0 => '${l10n.dayToday}, $dayMonth',
      1 => '${l10n.dayYesterday}, $dayMonth',
      _ => longDate(date),
    };
  }

  /// « Samedi 15 nov. 2026 ».
  String longDate(DateTime date) => capitalize(
    '${DateFormat('EEEE', locale).format(date.toLocal())} '
    '${AppDateFormat.dayMonthYear(date, locale)}',
  );

  /// « novembre », ou « novembre 2025 » hors de l'année en cours.
  String month(Month month) {
    final pattern = month.year == now.year ? 'MMMM' : 'MMMM y';
    return DateFormat(pattern, locale).format(month.start);
  }

  static String capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
