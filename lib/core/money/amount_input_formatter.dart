import 'package:flutter/services.dart';

import 'money.dart';

/// Saisie d'un montant en FCFA : chiffres uniquement, groupés au fil de la
/// frappe (`217500` → `217 500`), sans zéro initial.
class AmountInputFormatter extends TextInputFormatter {
  const AmountInputFormatter({this.maxDigits = 10});

  final int maxDigits;

  static final _nonDigits = RegExp(r'\D');
  static final _leadingZeros = RegExp(r'^0+(?=\d)');

  /// Montant représenté par un texte saisi (vide = 0).
  static Money parse(String text) {
    final digits = text.replaceAll(_nonDigits, '');
    return digits.isEmpty ? Money.zero : Money(int.parse(digits));
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text
        .replaceAll(_nonDigits, '')
        .replaceFirst(_leadingZeros, '');
    if (digits.length > maxDigits) return oldValue;

    final text = digits.isEmpty
        ? ''
        : MoneyFormat.amount(Money(int.parse(digits)));
    // Curseur toujours en fin de saisie : suffisant pour un montant.
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
