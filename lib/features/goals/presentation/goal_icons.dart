import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_icons.dart';
import '../../../l10n/l10n.dart';

/// Icône de la suggestion « Fonds d'urgence » (objectif conseillé :
/// 3 mois de dépenses).
const emergencyGoalIcon = 'umbrella';

/// Icône par défaut d'un objectif sans suggestion reconnue.
const defaultGoalIcon = 'piggy';

const _icons = {
  'phone': AppIcons.deviceMobile,
  'umbrella': AppIcons.umbrella,
  'airplane': AppIcons.airplane,
  'graduation': AppIcons.graduationCap,
  'heart': AppIcons.heart,
  'motorcycle': AppIcons.motorcycle,
  defaultGoalIcon: AppIcons.piggyBank,
};

IconData goalIcon(String key) => _icons[key] ?? AppIcons.piggyBank;

/// Suggestions de la maquette (« Pour quoi épargnes-tu ? ») et leur icône.
List<(String, String)> goalSuggestions(AppLocalizations l10n) => [
  (l10n.goalSuggestPhone, 'phone'),
  (l10n.goalSuggestEmergency, 'umbrella'),
  (l10n.goalSuggestTravel, 'airplane'),
  (l10n.goalSuggestStudies, 'graduation'),
  (l10n.goalSuggestWedding, 'heart'),
  (l10n.goalSuggestMoto, 'motorcycle'),
];

/// Icône déduite du nom : celle de la suggestion de même nom, sinon la
/// tirelire.
String goalIconKeyFor(String name, AppLocalizations l10n) {
  final normalized = name.trim().toLowerCase();
  for (final (label, key) in goalSuggestions(l10n)) {
    if (label.toLowerCase() == normalized) return key;
  }
  return defaultGoalIcon;
}
