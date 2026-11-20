import 'package:finance_app/core/time/month.dart';
import 'package:finance_app/features/transactions/domain/transaction_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Month monthOf(DateTime d) => Month.of(d, startDay: 25);

  test('semaine du lundi au dimanche', () {
    final week = TransactionPeriod.week(DateTime(2026, 11, 20, 18));

    expect(week.start, DateTime(2026, 11, 16));
    expect(week.last, DateTime(2026, 11, 22));
    expect(week.shift(-1).start, DateTime(2026, 11, 9));
  });

  test('mois budgétaire décalé et pas suivant', () {
    final month = TransactionPeriod.month(monthOf(DateTime(2026, 11, 20)));

    expect(month.start, DateTime(2026, 10, 25));
    expect(month.end, DateTime(2026, 11, 25));
    expect(month.shift(1).start, DateTime(2026, 11, 25));
    expect(month.shift(-2).start, DateTime(2026, 8, 25));
  });

  test('changer de pas garde l’ancre ; dates choisies dans le désordre', () {
    final month = TransactionPeriod.month(monthOf(DateTime(2026, 11, 20)));
    final day = month.withSpan(
      PeriodSpan.day,
      anchor: DateTime(2026, 11, 20),
      monthOf: monthOf,
    );
    final custom = TransactionPeriod.custom(
      DateTime(2026, 11, 15),
      DateTime(2026, 11, 1),
    );

    expect(day.start, DateTime(2026, 11, 20));
    expect(day.contains(DateTime(2026, 11, 20, 23, 59)), isTrue);
    expect(day.contains(DateTime(2026, 11, 21)), isFalse);
    expect(custom.start, DateTime(2026, 11));
    expect(custom.last, DateTime(2026, 11, 15));
    expect(custom.shift(1), custom);
  });
}
