import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_icons.dart';

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
      dividerTheme: DividerThemeData(
        color: colors.line,
        thickness: 1,
        space: 1,
      ),
      // Interrupteurs des maquettes : piste verte ou trait, pastille blanche.
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Color(0xFFFFFFFF)),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.line,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Color(0x00000000)),
      ),
      // En-têtes des maquettes : fond papier, titre centré 16/600, sans ombre.
      appBarTheme: AppBarTheme(
        // Fixé : une barre transparente (écrans teintés) ferait deviner des
        // icônes blanches à Flutter, invisibles sur le papier, et le réglage
        // resterait en revenant sur l'Accueil (qui n'a pas de barre).
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
              ),
        backgroundColor: colors.background,
        foregroundColor: colors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colors.ink,
        ),
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) =>
            const Icon(AppIcons.caretLeftBold, size: 20),
        closeButtonIconBuilder: (_) => const Icon(AppIcons.xBold, size: 20),
      ),
      // Boutons « pilule » de 52 px des maquettes.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: const StadiumBorder(),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.primary.withValues(alpha: 0.4),
          disabledForegroundColor: colors.onPrimary,
          textStyle: _buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: const StadiumBorder(),
          backgroundColor: colors.surface,
          foregroundColor: colors.ink,
          side: BorderSide(color: colors.line),
          textStyle: _buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: _buttonText.copyWith(fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        hintStyle: TextStyle(color: colors.inkTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: _inputBorder(colors.line),
        enabledBorder: _inputBorder(colors.line),
        focusedBorder: _inputBorder(colors.primary),
        errorBorder: _inputBorder(colors.negative),
        focusedErrorBorder: _inputBorder(colors.negative),
        errorStyle: TextStyle(color: colors.negative, fontSize: 12.5),
      ),
      // Bouton « Ajouter » : pilule libellée, toujours au même endroit.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: const StadiumBorder(),
        extendedSizeConstraints: const BoxConstraints.tightFor(height: 52),
        extendedPadding: const EdgeInsets.only(left: 18, right: 22),
        extendedTextStyle: _buttonText,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      extensions: [colors],
    );

    return base.copyWith(
      textTheme: _withTabularFigures(base.textTheme)
          .apply(bodyColor: colors.ink, displayColor: colors.ink),
    );
  }

  static const _buttonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color),
  );

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
