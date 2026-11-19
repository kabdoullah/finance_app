import 'package:finance_app/core/time/month.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mois calendaire (début le 1er) : inchangé', () {
    final m = Month.of(DateTime(2026, 11, 15));
    expect(m, const Month(2026, 11));
    expect(m.start, DateTime(2026, 11));
    expect(m.end, DateTime(2026, 12));
    expect(m.length, 30);
    expect(m.dayOf(DateTime(2026, 11, 15, 9)), 15);
    expect(m.daysLeft(DateTime(2026, 11, 15, 9)), 16);
    expect(m.previous, const Month(2026, 10));
    expect(Month.of(DateTime(2026, 1, 3)).previous, const Month(2025, 12));
  });

  test('début le 25 : nommé d\'après le mois de fin', () {
    final m = Month.of(DateTime(2026, 11, 15), startDay: 25);
    expect(m, const Month(2026, 11, startDay: 25));
    expect(m.start, DateTime(2026, 10, 25));
    expect(m.end, DateTime(2026, 11, 25));
    expect(m.length, 31);
    expect(m.dayOf(DateTime(2026, 11, 15)), 22);
    expect(m.daysLeft(DateTime(2026, 11, 15)), 10);
    // Le 25 ouvre la période suivante.
    expect(
      Month.of(DateTime(2026, 11, 25), startDay: 25),
      const Month(2026, 12, startDay: 25),
    );
    // Passage d'année.
    final january = Month.of(DateTime(2026, 12, 28), startDay: 25);
    expect(january, const Month(2027, 1, startDay: 25));
    expect(january.start, DateTime(2026, 12, 25));
    expect(january.previous.start, DateTime(2026, 11, 25));
  });

  test('début le 5 : nommé d\'après le mois de début', () {
    final m = Month.of(DateTime(2026, 11, 3), startDay: 5);
    expect(m, const Month(2026, 10, startDay: 5));
    expect(m.start, DateTime(2026, 10, 5));
    expect(m.end, DateTime(2026, 11, 5));
    expect(Month.of(DateTime(2026, 11, 5), startDay: 5).month, 11);
    expect(
      Month.of(DateTime(2026, 1, 2), startDay: 5),
      const Month(2025, 12, startDay: 5),
    );
  });

  test('début le 28 en février', () {
    final march = Month.of(DateTime(2026, 3, 10), startDay: 28);
    expect(march.start, DateTime(2026, 2, 28));
    expect(march.end, DateTime(2026, 3, 28));
    expect(march.length, 28);
    expect(march.contains(DateTime(2026, 3, 27, 23)), isTrue);
    expect(march.contains(DateTime(2026, 3, 28)), isFalse);
  });
}
