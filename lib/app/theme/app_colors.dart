import 'package:material_ui/material_ui.dart';

/// Jetons de couleur du design system « Piste A — Calme ».
///
/// Valeurs reprises telles quelles des maquettes (variables CSS `--bg`,
/// `--ink`, `--g`…). Chaque famille a une fonction : forêt pour agir,
/// sauge pour le positif, ambre pour épargner et la vigilance, terracotta
/// pour dépenser et alerter, ardoise pour prévoir, expliquer et les
/// transferts. Les neutres restent majoritaires.
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
    required this.primaryMid,
    required this.primaryTint,
    required this.positive,
    required this.warning,
    required this.warningMid,
    required this.warningSoft,
    required this.warningTint,
    required this.expense,
    required this.expenseMid,
    required this.expenseSoft,
    required this.negative,
    required this.negativeSoft,
    required this.info,
    required this.infoMid,
    required this.infoSoft,
    required this.infoTint,
    required this.chart,
    required this.expenseChart,
    required this.categories,
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

  /// Légendes.
  final Color inkTertiary;

  /// Filets de séparation (on préfère les filets aux cartes).
  final Color line;

  /// « Forêt » : actions et navigation active.
  final Color primary;
  final Color onPrimary;

  /// « Sauge » : fond doux et son texte, barre, teinte de section.
  final Color primarySoft;
  final Color onPrimarySoft;
  final Color primaryMid;
  final Color primaryTint;

  /// Montants positifs (revenus).
  final Color positive;

  /// « Ambre » : épargne, objectifs, vigilance (texte, barre, fond, teinte).
  final Color warning;
  final Color warningMid;
  final Color warningSoft;
  final Color warningTint;

  /// « Terracotta » : montants dépensés (texte, barre, fond).
  final Color expense;
  final Color expenseMid;
  final Color expenseSoft;

  /// Terracotta profond : dépassement, solde négatif, suppression.
  final Color negative;
  final Color negativeSoft;

  /// « Ardoise » : prévisions, informations, assistant, transferts.
  final Color info;
  final Color infoMid;
  final Color infoSoft;
  final Color infoTint;

  /// Teintes sauge de répartition, de la plus forte à la plus faible.
  final List<Color> chart;

  /// Teintes terracotta de la répartition des dépenses.
  final List<Color> expenseChart;

  /// Dix teintes sourdes des catégories ([CategoryHue]).
  final Map<CategoryHue, CategoryColors> categories;

  final Color scrim;

  /// Couleurs d'une catégorie d'après sa clé d'icône.
  CategoryColors category(String iconKey) =>
      categories[CategoryHue.ofIcon(iconKey)]!;

  static const light = AppColors(
    background: Color(0xFFF5F4EF),
    surface: Color(0xFFFFFFFF),
    chip: Color(0xFFECEBE5),
    ink: Color(0xFF1B1F1C),
    inkSecondary: Color(0xFF5B625D),
    inkTertiary: Color(0xFF646A65),
    line: Color(0xFFE4E3DC),
    primary: Color(0xFF1E4D3A),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFE2ECE4),
    onPrimarySoft: Color(0xFF2F5A44),
    primaryMid: Color(0xFF668F74),
    primaryTint: Color(0xFFE9F0EA),
    positive: Color(0xFF2E6E4C),
    warning: Color(0xFF87570F),
    warningMid: Color(0xFFB07A22),
    warningSoft: Color(0xFFF5EAD3),
    warningTint: Color(0xFFF8EFDD),
    expense: Color(0xFFA04A2C),
    expenseMid: Color(0xFFC06446),
    expenseSoft: Color(0xFFF6E3DA),
    negative: Color(0xFF8C3420),
    negativeSoft: Color(0xFFF3DCD3),
    info: Color(0xFF3E5A70),
    infoMid: Color(0xFF6A8599),
    infoSoft: Color(0xFFE4EBF0),
    infoTint: Color(0xFFE7EDF2),
    chart: [
      Color(0xFF2F5A44),
      Color(0xFF5E8A70),
      Color(0xFF93B5A0),
      Color(0xFFC7DACE),
      Color(0xFFDCE3DD),
    ],
    expenseChart: [
      Color(0xFFA04A2C),
      Color(0xFFC06446),
      Color(0xFFD9906F),
      Color(0xFFE7B59D),
      Color(0xFFF0D3C4),
    ],
    categories: {
      CategoryHue.food: CategoryColors(
        Color(0xFF7A5C25),
        Color(0xFFF3EBDD),
        Color(0xFFB5812A),
      ),
      CategoryHue.move: CategoryColors(
        Color(0xFF316368),
        Color(0xFFE0EDEE),
        Color(0xFF3F8C96),
      ),
      CategoryHue.home: CategoryColors(
        Color(0xFF6A4E63),
        Color(0xFFEFE7ED),
        Color(0xFF9A6A8E),
      ),
      CategoryHue.fun: CategoryColors(
        Color(0xFF865142),
        Color(0xFFF6E8E5),
        Color(0xFFC8705A),
      ),
      CategoryHue.bill: CategoryColors(
        Color(0xFF4F5478),
        Color(0xFFE8E9F2),
        Color(0xFF6F74B0),
      ),
      CategoryHue.care: CategoryColors(
        Color(0xFF456B51),
        Color(0xFFE5EFE8),
        Color(0xFF5E9A72),
      ),
      CategoryHue.family: CategoryColors(
        Color(0xFF63612D),
        Color(0xFFEDECDF),
        Color(0xFF8F8A37),
      ),
      CategoryHue.education: CategoryColors(
        Color(0xFF455F7F),
        Color(0xFFE5ECF4),
        Color(0xFF5F86BC),
      ),
      CategoryHue.clothing: CategoryColors(
        Color(0xFF815161),
        Color(0xFFF5E8ED),
        Color(0xFFC06F8C),
      ),
      CategoryHue.other: CategoryColors(
        Color(0xFF606460),
        Color(0xFFECEDEC),
        Color(0xFF8A8F8A),
      ),
    },
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
    primaryMid: Color(0xFF5E8C70),
    primaryTint: Color(0xFF16201A),
    positive: Color(0xFF8CCBA4),
    warning: Color(0xFFE2B568),
    warningMid: Color(0xFFB98A3A),
    warningSoft: Color(0xFF2E2617),
    warningTint: Color(0xFF211D14),
    expense: Color(0xFFE99A7C),
    expenseMid: Color(0xFFB86A4C),
    expenseSoft: Color(0xFF33201A),
    negative: Color(0xFFF08F78),
    negativeSoft: Color(0xFF3A1E18),
    info: Color(0xFFA9C1D4),
    infoMid: Color(0xFF5F7C92),
    infoSoft: Color(0xFF1B2630),
    infoTint: Color(0xFF151C22),
    chart: [
      Color(0xFF86C7A0),
      Color(0xFF5E9C78),
      Color(0xFF427358),
      Color(0xFF2E4D3C),
      Color(0xFF2A302C),
    ],
    expenseChart: [
      Color(0xFFE99A7C),
      Color(0xFFC97A5D),
      Color(0xFFA35F46),
      Color(0xFF7D4A37),
      Color(0xFF553529),
    ],
    categories: {
      CategoryHue.food: CategoryColors(
        Color(0xFFCFAD75),
        Color(0xFF37301C),
        Color(0xFF9D7227),
      ),
      CategoryHue.move: CategoryColors(
        Color(0xFF82B4BB),
        Color(0xFF203232),
        Color(0xFF397B83),
      ),
      CategoryHue.home: CategoryColors(
        Color(0xFFBD9EB6),
        Color(0xFF322C30),
        Color(0xFF865E7C),
      ),
      CategoryHue.fun: CategoryColors(
        Color(0xFFDBA294),
        Color(0xFF3B2D26),
        Color(0xFFAE6350),
      ),
      CategoryHue.bill: CategoryColors(
        Color(0xFFA1A5CC),
        Color(0xFF292E37),
        Color(0xFF626799),
      ),
      CategoryHue.care: CategoryColors(
        Color(0xFF96BDA3),
        Color(0xFF26352B),
        Color(0xFF538765),
      ),
      CategoryHue.family: CategoryColors(
        Color(0xFFB6B37D),
        Color(0xFF30321F),
        Color(0xFF7D7A32),
      ),
      CategoryHue.education: CategoryColors(
        Color(0xFF97B0D3),
        Color(0xFF26313A),
        Color(0xFF5476A4),
      ),
      CategoryHue.clothing: CategoryColors(
        Color(0xFFD6A1B4),
        Color(0xFF3A2D30),
        Color(0xFFA7637B),
      ),
      CategoryHue.other: CategoryColors(
        Color(0xFFB3B6B3),
        Color(0xFF2F3330),
        Color(0xFF797E79),
      ),
    },
    scrim: Color(0x8C000000),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    List<Color> mixAll(List<Color> a, List<Color> b) => [
      for (var i = 0; i < a.length; i++) mix(a[i], b[i]),
    ];
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
      primaryMid: mix(primaryMid, other.primaryMid),
      primaryTint: mix(primaryTint, other.primaryTint),
      positive: mix(positive, other.positive),
      warning: mix(warning, other.warning),
      warningMid: mix(warningMid, other.warningMid),
      warningSoft: mix(warningSoft, other.warningSoft),
      warningTint: mix(warningTint, other.warningTint),
      expense: mix(expense, other.expense),
      expenseMid: mix(expenseMid, other.expenseMid),
      expenseSoft: mix(expenseSoft, other.expenseSoft),
      negative: mix(negative, other.negative),
      negativeSoft: mix(negativeSoft, other.negativeSoft),
      info: mix(info, other.info),
      infoMid: mix(infoMid, other.infoMid),
      infoSoft: mix(infoSoft, other.infoSoft),
      infoTint: mix(infoTint, other.infoTint),
      chart: mixAll(chart, other.chart),
      expenseChart: mixAll(expenseChart, other.expenseChart),
      categories: {
        for (final hue in CategoryHue.values)
          hue: CategoryColors.lerp(categories[hue]!, other.categories[hue]!, t),
      },
      scrim: mix(scrim, other.scrim),
    );
  }
}

/// Teintes de catégorie du design system : elles identifient une
/// catégorie, jamais un état.
enum CategoryHue {
  food,
  move,
  home,
  fun,
  bill,
  care,
  family,
  education,
  clothing,
  other;

  /// Teinte d'une catégorie d'après sa clé d'icône (les catégories
  /// personnalisées héritent de l'icône choisie).
  static CategoryHue ofIcon(String iconKey) => switch (iconKey) {
    'basket' => food,
    'taxi' => move,
    'house-line' => home,
    'ticket' || 'gift' => fun,
    'receipt' || 'device-mobile' => bill,
    'heartbeat' => care,
    'users' || 'hand-coins' => family,
    'graduation-cap' => education,
    't-shirt' => clothing,
    _ => other,
  };
}

/// Couleurs d'une catégorie : encre de l'icône, fond très clair,
/// teinte moyenne des graphiques.
@immutable
class CategoryColors {
  const CategoryColors(this.ink, this.background, this.mid);

  final Color ink;
  final Color background;
  final Color mid;

  static CategoryColors lerp(CategoryColors a, CategoryColors b, double t) =>
      CategoryColors(
        Color.lerp(a.ink, b.ink, t)!,
        Color.lerp(a.background, b.background, t)!,
        Color.lerp(a.mid, b.mid, t)!,
      );
}

/// Accès court aux jetons : `context.colors.ink`.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
