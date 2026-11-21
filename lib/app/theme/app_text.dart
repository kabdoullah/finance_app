import 'package:material_ui/material_ui.dart';

/// Échelle typographique du design system : Manrope seule, chiffres
/// tabulaires. Chaque jeton fixe la taille, la graisse et l'interlettrage ;
/// la couleur reste à l'appelant (`AppText.label.copyWith(color: …)`), la
/// graisse se module avec [AppTextWeight] (`AppText.body.semibold`).
///
/// Tailles reprises des maquettes ; on n'en ajoute une qu'avec un nouveau
/// rôle, jamais pour un écran.
abstract final class AppText {
  static const fontFamily = 'Manrope';

  static const _tabular = [FontFeature.tabularFigures()];

  // Titres.

  /// Grand titre d'un onglet (Opérations, Budgets, Objectifs, Prévisions,
  /// Assistant).
  static const screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );

  /// Titre d'un écran de résultat (« Opération enregistrée »).
  static const title = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  /// Titre d'un bloc mis en avant (carte d'objectif, simulation).
  static const headline = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  /// Titre d'une feuille du bas ou d'une boîte de dialogue.
  static const sheetTitle = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  /// Titre de section dans un écran (« Où va l'argent »).
  static const sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  /// Titre de barre d'application, unité d'un grand montant.
  static const subtitle = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // Texte courant (graisse normale ; `.semibold` pour un titre de ligne).

  /// Titre de ligne (en `.semibold`), texte saisi, bouton.
  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 15,
  );

  /// Texte courant, explications.
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 14,
  );

  /// Texte d'appoint sous un titre, réponses de l'assistant.
  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 13.5,
  );

  /// Libellé de champ (en `.medium`), métadonnées d'une ligne.
  static const label = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 13,
  );

  /// Légende, date, sous-ligne d'une opération, message d'erreur.
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 12.5,
  );

  /// Légende de graphique, mention discrète.
  static const small = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 12,
  );

  /// Surtitre de groupe, à écrire en majuscules (« SÉCURITÉ »).
  static const overline = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  );

  /// Pastille d'état (« À vérifier »), libellé d'onglet.
  static const tag = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  /// Chiffre d'une touche du pavé de saisie.
  static const keypadKey = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  /// Chiffre d'une touche du pavé du code PIN.
  static const pinKey = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 28,
    fontWeight: FontWeight.w500,
  );

  // Montants.

  /// Grand montant : chiffres serrés de 3,5 % de la taille, sans interligne,
  /// comme sur toutes les maquettes. La taille dépend de la place du montant
  /// (saisie 54, solde de l'Accueil 46, détail 38…). [inline] garde
  /// l'interligne du texte pour un chiffre clé pris dans une colonne de
  /// texte (totaux du mois, prévision de l'Accueil).
  static TextStyle amount(double size, {bool inline = false}) => TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: size,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.035 * size,
    height: inline ? null : 1,
  );
}

/// Graisses et interligne de lecture, à appliquer sur un jeton [AppText].
extension AppTextWeight on TextStyle {
  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get semibold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);

  /// Paragraphe sur plusieurs lignes.
  TextStyle get prose => copyWith(height: 1.45);
}
