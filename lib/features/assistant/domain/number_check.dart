/// Contrôle déterministe des réponses de Gemma : il explique les chiffres de
/// l'application, il n'en invente pas. Tout nombre de sa phrase doit figurer
/// dans les résultats des outils (ou dans la question).
abstract final class NumberCheck {
  /// « 35 000 », « 35 000 », « 35.000 » ou « 35000 » → 35000.
  static final _number = RegExp(r'\d{1,3}(?:[ \u00a0\u202f.]\d{3})+(?!\d)|\d+');
  static final _separators = RegExp(r'[ \u00a0\u202f.]');

  /// Nombres entiers écrits dans [text].
  static Set<int> inText(String text) => {
    for (final match in _number.allMatches(text))
      ?int.tryParse(match.group(0)!.replaceAll(_separators, '')),
  };

  /// Nombres contenus dans un résultat d'outil (valeurs, listes, textes).
  static Set<int> inData(Object? data) => switch (data) {
    final int n => {n, n.abs()},
    final double d => {d.round(), d.round().abs()},
    final String s => inText(s),
    final Map<Object?, Object?> map => {
      for (final value in map.values) ...inData(value),
    },
    final Iterable<Object?> list => {for (final item in list) ...inData(item)},
    _ => const {},
  };

  /// Vrai si chaque nombre de [text] est dans [allowed].
  static bool usesOnly(String text, Set<int> allowed) =>
      inText(text).every(allowed.contains);
}
