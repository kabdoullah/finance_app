import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source de l'heure courante, injectable pour rendre les calculs et les tests
/// déterministes (prévisions, échéances, date affichée).
typedef Clock = DateTime Function();

final clockProvider = Provider<Clock>((ref) => DateTime.now);
