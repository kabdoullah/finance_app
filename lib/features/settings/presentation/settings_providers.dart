import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;

import '../../../core/errors/error_reporter.dart';
import '../../../core/time/month.dart';
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

/// Début du mois budgétaire (« Le 1er » par défaut). Lu avant le lancement
/// (`main`) pour qu'aucun total ne soit d'abord calculé sur le mauvais mois.
class BudgetMonthStart extends Notifier<int> {
  BudgetMonthStart([this._initial]);

  final int? _initial;

  @override
  int build() {
    if (_initial case final day?) return day;
    unawaited(_load());
    return 1;
  }

  Future<void> _load() async {
    try {
      state = await ref.read(appPreferencesProvider).budgetMonthStart();
    } on Object catch (error, stack) {
      reportError(error, stack);
    }
  }

  Future<void> set(int day) async {
    state = day.clamp(1, Month.maxStartDay);
    await ref.read(appPreferencesProvider).setBudgetMonthStart(state);
  }
}

final budgetMonthStartProvider = NotifierProvider<BudgetMonthStart, int>(
  BudgetMonthStart.new,
);

/// Mois budgétaire d'une date, selon le réglage.
typedef MonthOf = Month Function(DateTime date);

final monthOfProvider = Provider<MonthOf>((ref) {
  final startDay = ref.watch(budgetMonthStartProvider);
  return (date) => Month.of(date, startDay: startDay);
});
