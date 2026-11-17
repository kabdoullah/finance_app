/// Pourcentages entiers de [amounts] (positifs) dont la somme vaut exactement
/// 100 : méthode du plus fort reste ; à reste égal, la première part l'emporte.
///
/// Utilisé par toutes les répartitions affichées (comptes, dépenses…).
List<int> splitPercentages(List<int> amounts) {
  final total = amounts.fold<int>(0, (sum, a) => sum + a);
  if (total <= 0) return [for (final _ in amounts) 0];

  final floors = [for (final a in amounts) a * 100 ~/ total];
  final remainders = [for (final a in amounts) a * 100 % total];
  final order = List<int>.generate(amounts.length, (i) => i)
    ..sort((i, j) {
      final byRemainder = remainders[j].compareTo(remainders[i]);
      return byRemainder != 0 ? byRemainder : i.compareTo(j);
    });

  var missing = 100 - floors.fold<int>(0, (sum, p) => sum + p);
  for (final i in order) {
    if (missing == 0) break;
    floors[i]++;
    missing--;
  }
  return floors;
}
