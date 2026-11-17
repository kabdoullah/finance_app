/// Recherche tolérante : sans casse ni accents (« electricite » trouve
/// « Électricité »).
abstract final class TextSearch {
  static const _accents = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'á': 'a',
    'ã': 'a',
    'ç': 'c',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'í': 'i',
    'ì': 'i',
    'ô': 'o',
    'ö': 'o',
    'ó': 'o',
    'ò': 'o',
    'õ': 'o',
    'û': 'u',
    'ù': 'u',
    'ü': 'u',
    'ú': 'u',
    'ÿ': 'y',
    'ñ': 'n',
    'œ': 'oe',
    'æ': 'ae',
  };

  static String normalize(String text) {
    final buffer = StringBuffer();
    for (final char in text.toLowerCase().split('')) {
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString().trim();
  }

  /// Vrai si [query] (normalisée) apparaît dans l'un des [fields].
  static bool matches(String query, Iterable<String?> fields) {
    final needle = normalize(query);
    if (needle.isEmpty) return true;
    return fields.any(
      (field) => field != null && normalize(field).contains(needle),
    );
  }
}
