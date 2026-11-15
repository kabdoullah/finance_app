import 'package:intl/intl.dart';

/// Montant en francs CFA (XOF).
///
/// Le XOF n'a pas de subdivision : un entier suffit et évite toute erreur
/// d'arrondi. On n'utilise jamais `double` pour un montant.
extension type const Money(int value) {
  static const zero = Money(0);

  Money operator +(Money other) => Money(value + other.value);
  Money operator -(Money other) => Money(value - other.value);
  Money operator -() => Money(-value);

  bool get isNegative => value < 0;
}

/// Formatage des montants pour l'affichage, sans abréviation ni devise :
/// `217500` → `217 500`. La devise (« FCFA ») est affichée à part, plus petite,
/// comme dans les maquettes.
abstract final class MoneyFormat {
  static final _digits = NumberFormat('#,##0', 'fr');

  /// Signe moins typographique (U+2212), comme dans les maquettes.
  static const _minus = '−';

  /// Montant en valeur absolue : `-8500` → `8 500`.
  static String amount(Money money) => _digits.format(money.value.abs());

  /// Montant signé : `-8500` → `−8 500`, `45000` → `+45 000`, `0` → `0`.
  static String signed(Money money) {
    if (money.value == 0) return amount(money);
    return '${money.isNegative ? _minus : '+'}${amount(money)}';
  }
}
