import 'package:finance_app/core/money/amount_input_formatter.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

const _nnbsp = '\u00a0';

String _type(String text, {String previous = ''}) => const AmountInputFormatter()
    .formatEditUpdate(
      TextEditingValue(text: previous),
      TextEditingValue(text: text),
    )
    .text;

void main() {
  test('groupe les milliers au fil de la frappe', () {
    expect(_type('217500'), '217${_nnbsp}500');
  });

  test('ignore tout ce qui n’est pas un chiffre et les zéros initiaux', () {
    expect(_type('00 1a2-5'), '125');
    expect(_type('0'), '0');
    expect(_type(''), '');
  });

  test('refuse au-delà de 10 chiffres', () {
    expect(_type('12345678901', previous: '1 234'), '1 234');
  });

  test('parse relit le montant affiché', () {
    expect(AmountInputFormatter.parse('217${_nnbsp}500'), const Money(217500));
    expect(AmountInputFormatter.parse(''), Money.zero);
  });
}
