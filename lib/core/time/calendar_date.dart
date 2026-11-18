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
