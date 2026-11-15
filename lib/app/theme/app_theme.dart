import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Thème global : Manrope seule, chiffres tabulaires partout (les montants
/// restent alignés), couleurs issues de [AppColors].
abstract final class AppTheme {
  static const fontFamily = 'Manrope';

  static final ThemeData light = _build(AppColors.light, Brightness.light);
  static final ThemeData dark = _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primarySoft,
      onPrimaryContainer: colors.onPrimarySoft,
      secondary: colors.primary,
      onSecondary: colors.onPrimary,
      error: colors.negative,
      onError: colors.onPrimary,
      errorContainer: colors.negativeSoft,
      onErrorContainer: colors.negative,
      surface: colors.background,
      onSurface: colors.ink,
      onSurfaceVariant: colors.inkSecondary,
      surfaceContainerLowest: colors.surface,
      surfaceContainerHighest: colors.chip,
      outline: colors.inkTertiary,
      outlineVariant: colors.line,
      scrim: colors.scrim,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: colors.background,
      dividerTheme: DividerThemeData(color: colors.line, thickness: 1, space: 1),
      extensions: [colors],
    );

    return base.copyWith(
      textTheme: _withTabularFigures(base.textTheme).apply(
        bodyColor: colors.ink,
        displayColor: colors.ink,
      ),
    );
  }

  /// Applique `tnum` à tous les styles, comme `font-variant-numeric:
  /// tabular-nums` sur la racine des maquettes.
  static TextTheme _withTabularFigures(TextTheme theme) {
    const tabular = [FontFeature.tabularFigures()];
    TextStyle? tnum(TextStyle? s) => s?.copyWith(fontFeatures: tabular);
    return theme.copyWith(
      displayLarge: tnum(theme.displayLarge),
      displayMedium: tnum(theme.displayMedium),
      displaySmall: tnum(theme.displaySmall),
      headlineLarge: tnum(theme.headlineLarge),
      headlineMedium: tnum(theme.headlineMedium),
      headlineSmall: tnum(theme.headlineSmall),
      titleLarge: tnum(theme.titleLarge),
      titleMedium: tnum(theme.titleMedium),
      titleSmall: tnum(theme.titleSmall),
      bodyLarge: tnum(theme.bodyLarge),
      bodyMedium: tnum(theme.bodyMedium),
      bodySmall: tnum(theme.bodySmall),
      labelLarge: tnum(theme.labelLarge),
      labelMedium: tnum(theme.labelMedium),
      labelSmall: tnum(theme.labelSmall),
    );
  }
}
