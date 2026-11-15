import 'package:material_ui/material_ui.dart';

/// Jetons de couleur de la direction artistique « Piste A — Calme ».
///
/// Valeurs reprises telles quelles des maquettes (variables CSS `--bg`,
/// `--ink`, `--g`…). Règle de sens : vert pour l'action, ambre pour la
/// vigilance, brique uniquement pour le négatif.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.chip,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.line,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.onPrimarySoft,
    required this.positive,
    required this.warning,
    required this.warningSoft,
    required this.negative,
    required this.negativeSoft,
    required this.chart,
    required this.scrim,
  });

  /// Fond « Papier ».
  final Color background;
  final Color surface;

  /// Fond neutre des pastilles et icônes.
  final Color chip;

  /// Texte principal « Encre ».
  final Color ink;
  final Color inkSecondary;
  final Color inkTertiary;

  /// Filets de séparation (on préfère les filets aux cartes).
  final Color line;

  /// « Forêt » : actions et navigation active.
  final Color primary;
  final Color onPrimary;

  /// « Sauge » : fonds doux et gains.
  final Color primarySoft;
  final Color onPrimarySoft;

  /// Montants positifs (revenus).
  final Color positive;

  /// « Ambre » : avertissement.
  final Color warning;
  final Color warningSoft;

  /// « Brique » : négatif uniquement.
  final Color negative;
  final Color negativeSoft;

  /// Teintes de répartition (une seule famille), de la plus forte à la plus faible.
  final List<Color> chart;

  final Color scrim;

  static const light = AppColors(
    background: Color(0xFFF5F4EF),
    surface: Color(0xFFFFFFFF),
    chip: Color(0xFFECEBE5),
    ink: Color(0xFF1B1F1C),
    inkSecondary: Color(0xFF5B625D),
    inkTertiary: Color(0xFF737974),
    line: Color(0xFFE4E3DC),
    primary: Color(0xFF1E4D3A),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFE2ECE4),
    onPrimarySoft: Color(0xFF1E4D3A),
    positive: Color(0xFF2B7550),
    warning: Color(0xFFA85F0E),
    warningSoft: Color(0xFFF7EBDA),
    negative: Color(0xFFB0362A),
    negativeSoft: Color(0xFFF6E1DD),
    chart: [
      Color(0xFF1E4D3A),
      Color(0xFF4C8264),
      Color(0xFF88B297),
      Color(0xFFBFD6C6),
      Color(0xFFDCE3DD),
    ],
    scrim: Color(0x61141815),
  );

  static const dark = AppColors(
    background: Color(0xFF101311),
    surface: Color(0xFF181C19),
    chip: Color(0xFF222723),
    ink: Color(0xFFECEEEA),
    inkSecondary: Color(0xFFA2A9A3),
    inkTertiary: Color(0xFF8A918B),
    line: Color(0xFF272C28),
    primary: Color(0xFF86C7A0),
    onPrimary: Color(0xFF0D1912),
    primarySoft: Color(0xFF1C2D23),
    onPrimarySoft: Color(0xFF9FD5B5),
    positive: Color(0xFF86C7A0),
    warning: Color(0xFFE3A45B),
    warningSoft: Color(0xFF32261A),
    negative: Color(0xFFEE8B7F),
    negativeSoft: Color(0xFF3A201D),
    chart: [
      Color(0xFF86C7A0),
      Color(0xFF5E9C78),
      Color(0xFF427358),
      Color(0xFF2E4D3C),
      Color(0xFF2A302C),
    ],
    scrim: Color(0x8C000000),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      chip: mix(chip, other.chip),
      ink: mix(ink, other.ink),
      inkSecondary: mix(inkSecondary, other.inkSecondary),
      inkTertiary: mix(inkTertiary, other.inkTertiary),
      line: mix(line, other.line),
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      primarySoft: mix(primarySoft, other.primarySoft),
      onPrimarySoft: mix(onPrimarySoft, other.onPrimarySoft),
      positive: mix(positive, other.positive),
      warning: mix(warning, other.warning),
      warningSoft: mix(warningSoft, other.warningSoft),
      negative: mix(negative, other.negative),
      negativeSoft: mix(negativeSoft, other.negativeSoft),
      chart: [
        for (var i = 0; i < chart.length; i++) mix(chart[i], other.chart[i]),
      ],
      scrim: mix(scrim, other.scrim),
    );
  }
}

/// Accès court aux jetons : `context.colors.ink`.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
