import 'package:finance_app/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

/// Espace fine insécable (U+202F), séparateur de milliers en français.
const _nnbsp = ' ';

void main() {
  group('Money', () {
    test('additionne et soustrait sans perte', () {
      expect(const Money(217500) + const Money(25000), const Money(242500));
      expect(const Money(8500) - const Money(10000), const Money(-1500));
      expect(-const Money(500), const Money(-500));
    });

    test('isNegative', () {
      expect(const Money(-1).isNegative, isTrue);
      expect(Money.zero.isNegative, isFalse);
    });
  });

  group('MoneyFormat', () {
    test('groupe les milliers à la française, sans abréviation', () {
      expect(MoneyFormat.amount(const Money(217500)), '217${_nnbsp}500');
      expect(
        MoneyFormat.amount(const Money(1250000)),
        '1${_nnbsp}250${_nnbsp}000',
      );
      expect(MoneyFormat.amount(Money.zero), '0');
    });

    test('amount affiche la valeur absolue', () {
      expect(MoneyFormat.amount(const Money(-8500)), '8${_nnbsp}500');
    });

    test('signed utilise le signe moins typographique', () {
      expect(MoneyFormat.signed(const Money(-8500)), '−8${_nnbsp}500');
      expect(MoneyFormat.signed(const Money(45000)), '+45${_nnbsp}000');
      expect(MoneyFormat.signed(Money.zero), '0');
    });
  });
}
