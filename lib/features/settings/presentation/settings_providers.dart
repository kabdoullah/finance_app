import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;

import '../../../core/errors/error_reporter.dart';
import '../data/app_preferences.dart';

/// Thème choisi dans les Paramètres (Automatique par défaut).
class ThemeModeSetting extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    unawaited(_load());
    return ThemeMode.system;
  }

  Future<void> _load() async {
    try {
      state = await ref.read(appPreferencesProvider).themeMode();
    } on Object catch (error, stack) {
      reportError(error, stack);
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(appPreferencesProvider).setThemeMode(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeSetting, ThemeMode>(
  ThemeModeSetting.new,
);

/// Réglage « Masquer les montants à l'ouverture ».
class HideAmountsSetting extends Notifier<bool> {
  @override
  bool build() {
    unawaited(_load());
    return false;
  }

  Future<void> _load() async {
    try {
      state = await ref.read(appPreferencesProvider).hideAmountsAtLaunch();
    } on Object catch (error, stack) {
      reportError(error, stack);
    }
  }

  Future<void> set(bool value) async {
    state = value;
    // Appliqué tout de suite à l'accueil.
    ref.read(amountsHiddenProvider.notifier).setHidden(value);
    await ref.read(appPreferencesProvider).setHideAmountsAtLaunch(value);
  }
}

final hideAmountsSettingProvider = NotifierProvider<HideAmountsSetting, bool>(
  HideAmountsSetting.new,
);

/// Montants de l'accueil masqués (« •••• ») pour cette session : masqués au
/// lancement si le réglage est activé, affichés par le bouton œil.
class AmountsHidden extends Notifier<bool> {
  @override
  bool build() {
    // Masqué tant que le réglage n'est pas lu : jamais de montant affiché
    // par erreur au lancement.
    unawaited(_load());
    return true;
  }

  Future<void> _load() async {
    try {
      state = await ref.read(appPreferencesProvider).hideAmountsAtLaunch();
    } on Object catch (error, stack) {
      reportError(error, stack);
      state = false;
    }
  }

  void setHidden(bool value) => state = value;

  void toggle() => state = !state;
}

final amountsHiddenProvider = NotifierProvider<AmountsHidden, bool>(
  AmountsHidden.new,
);
