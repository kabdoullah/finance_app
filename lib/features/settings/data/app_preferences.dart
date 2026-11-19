import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Préférences d'affichage (pas des données financières : hors base
/// chiffrée).
class AppPreferences {
  const AppPreferences(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _themeKey = 'ui.themeMode';
  static const _hideAmountsKey = 'privacy.hideAmounts';

  Future<ThemeMode> themeMode() async {
    final value = await _prefs.getString(_themeKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_themeKey, mode.name);

  Future<bool> hideAmountsAtLaunch() async =>
      await _prefs.getBool(_hideAmountsKey) ?? false;

  Future<void> setHideAmountsAtLaunch(bool value) =>
      _prefs.setBool(_hideAmountsKey, value);
}

final appPreferencesProvider = Provider<AppPreferences>(
  (ref) => AppPreferences(SharedPreferencesAsync()),
);
