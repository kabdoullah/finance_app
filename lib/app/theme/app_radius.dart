/// Rayons d'arrondi du design system, à passer à `BorderRadius.circular` ou
/// `Radius.circular`. Les micro-marques des graphiques (légendes, barres de
/// fiabilité) gardent leur propre géométrie.
abstract final class AppRadius {
  /// Étiquette d'état, badge, pointe d'une bulle.
  static const double xs = 6;

  /// Petite pastille, jour du calendrier, segment actif.
  static const double sm = 10;

  /// Encadré d'information, tuile, fond d'un sélecteur segmenté.
  static const double md = 12;

  /// Champ de saisie, bloc de formulaire.
  static const double field = 14;

  /// Carte, bulle de l'assistant.
  static const double lg = 16;

  /// Boîte de dialogue, carte du calendrier.
  static const double xl = 20;

  /// Haut d'une feuille du bas.
  static const double sheet = 24;

  /// Pilule : Flutter ramène le rayon à la moitié de la hauteur (barres,
  /// jauges, boutons).
  static const double pill = 999;
}
