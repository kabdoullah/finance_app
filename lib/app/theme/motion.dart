import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Mouvement des maquettes (Motion) : rapide, utile, calme. Une animation
/// part de l'élément touché et finit sur le résultat ; l'action n'attend
/// jamais la fin de l'animation.
abstract final class Motion {
  /// Pression, interrupteur, case.
  static const fast = Duration(milliseconds: 150);

  /// Fondu, changement de valeur, filtre, feuille qui se ferme.
  static const base = Duration(milliseconds: 220);

  /// Apparition, couleur d'état, barre qui change, feuille qui s'ouvre.
  static const slow = Duration(milliseconds: 300);

  /// Tracé de courbe, remplissage, compteur de solde.
  static const chart = Duration(milliseconds: 650);

  /// Montant qui change (totaux d'un filtre).
  static const count = Duration(milliseconds: 360);

  /// Barres qui se remplissent.
  static const fill = Duration(milliseconds: 560);

  /// Ce qui bouge d'un état à un autre.
  static const ease = Cubic(0.2, 0, 0, 1);

  /// Ce qui apparaît.
  static const easeOut = Cubic(0, 0, 0.2, 1);

  /// Ce qui disparaît (plus court que l'entrée).
  static const easeIn = Cubic(0.4, 0, 1, 1);

  /// Décalage entre éléments d'une cascade, 6 au maximum.
  static const stagger = Duration(milliseconds: 40);
  static const maxStagger = 6;

  /// Un montant compte de 92 % à 100 % de sa valeur, jamais depuis zéro.
  static const countFrom = 0.92;

  /// « Réduire les animations » du système : tout devient instantané.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], ou zéro si les animations sont réduites.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}

/// Retours haptiques des maquettes ; Android et iOS les règlent dans leurs
/// paramètres (« Vibration au toucher »).
abstract final class Haptics {
  /// Interrupteur, segment, puce.
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// Début et fin de dictée, seuil de « glisser pour supprimer ».
  static Future<void> light() => HapticFeedback.lightImpact();

  /// Suppression.
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// Opération enregistrée, objectif atteint.
  static Future<void> success() => HapticFeedback.mediumImpact();

  /// Budget dépassé (une fois).
  static Future<void> warning() => HapticFeedback.heavyImpact();
}
