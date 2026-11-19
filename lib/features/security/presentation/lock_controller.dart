import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/errors/error_reporter.dart';
import '../data/biometric_service.dart';
import '../data/pin_store.dart';
import '../domain/pin_policy.dart';

/// Résultat d'un code saisi.
enum PinCheck { ok, wrong, waiting }

@immutable
class LockState {
  const LockState({
    this.loaded = false,
    this.enabled = false,
    this.locked = false,
    this.biometric = false,
    this.biometricAvailable = false,
    this.delay = LockDelay.oneMinute,
    this.failures = 0,
    this.waitUntil,
  });

  /// Réglages lus : avant, rien n'est affiché (pas d'aperçu des données).
  final bool loaded;
  final bool enabled;
  final bool locked;
  final bool biometric;
  final bool biometricAvailable;
  final LockDelay delay;
  final int failures;
  final DateTime? waitUntil;

  LockState copyWith({
    bool? loaded,
    bool? enabled,
    bool? locked,
    bool? biometric,
    bool? biometricAvailable,
    LockDelay? delay,
    int? failures,
    DateTime? Function()? waitUntil,
  }) => LockState(
    loaded: loaded ?? this.loaded,
    enabled: enabled ?? this.enabled,
    locked: locked ?? this.locked,
    biometric: biometric ?? this.biometric,
    biometricAvailable: biometricAvailable ?? this.biometricAvailable,
    delay: delay ?? this.delay,
    failures: failures ?? this.failures,
    waitUntil: waitUntil == null ? this.waitUntil : waitUntil(),
  );
}

/// Verrouillage de l'application : au lancement, puis au retour après le
/// délai « Verrouiller après ».
class LockController extends Notifier<LockState> {
  DateTime? _hiddenAt;

  /// Pendant une demande d'empreinte, l'application passe en arrière-plan :
  /// ce passage ne doit pas reverrouiller.
  bool _authenticating = false;

  PinStore get _store => ref.read(pinStoreProvider);
  DateTime get _now => ref.read(clockProvider)();

  @override
  LockState build() {
    unawaited(_load());
    return const LockState();
  }

  Future<void> _load() async {
    try {
      final settings = await _store.read();
      state = LockState(
        loaded: true,
        enabled: settings.enabled,
        locked: settings.enabled,
        biometric: settings.biometric,
        delay: settings.delay,
        failures: settings.failures,
        waitUntil: settings.waitUntil,
      );
    } on Object catch (error, stack) {
      // Coffre illisible : l'application reste accessible plutôt que bloquée
      // sans issue (la base reste chiffrée par sa propre clé).
      reportError(error, stack);
      state = state.copyWith(loaded: true);
      return;
    }
    // Ensuite seulement : ces appels Android ne retardent pas l'affichage.
    unawaited(ref.read(secureWindowProvider).set(state.enabled));
    final available = await ref.read(biometricServiceProvider).isAvailable();
    state = state.copyWith(
      biometricAvailable: available,
      biometric: state.biometric && available,
    );
  }

  void onHidden() {
    if (!_authenticating) _hiddenAt ??= _now;
  }

  void onResumed() {
    final hiddenAt = _hiddenAt;
    _hiddenAt = null;
    if (!state.enabled || state.locked || hiddenAt == null) return;
    if (_now.difference(hiddenAt) >= state.delay.duration) {
      state = state.copyWith(locked: true);
    }
  }

  /// Attente imposée restante, ou `null`.
  Duration? remainingWait() {
    final until = state.waitUntil;
    if (until == null) return null;
    final left = until.difference(_now);
    return left > Duration.zero ? left : null;
  }

  /// Vérifie [pin] ; déverrouille s'il est bon.
  Future<PinCheck> unlock(String pin) async {
    final check = await verify(pin);
    if (check == PinCheck.ok) state = state.copyWith(locked: false);
    return check;
  }

  /// Vérifie [pin] en comptant les essais ratés (déverrouillage, mais aussi
  /// modification ou désactivation depuis les Paramètres).
  Future<PinCheck> verify(String pin) async {
    if (remainingWait() != null) return PinCheck.waiting;
    if (await _store.verify(pin)) {
      if (state.failures > 0 || state.waitUntil != null) {
        await _store.resetFailures();
        state = state.copyWith(failures: 0, waitUntil: () => null);
      }
      return PinCheck.ok;
    }
    final failures = state.failures + 1;
    final wait = PinPolicy.waitAfter(failures);
    final until = wait == null ? null : _now.add(wait);
    state = state.copyWith(failures: failures, waitUntil: () => until);
    await _store.saveFailures(failures, until);
    return wait == null ? PinCheck.wrong : PinCheck.waiting;
  }

  Future<bool> unlockWithBiometrics(String reason) async {
    if (!state.biometric) return false;
    _authenticating = true;
    try {
      final ok = await ref.read(biometricServiceProvider).authenticate(reason);
      if (ok) {
        await _store.resetFailures();
        state = state.copyWith(
          locked: false,
          failures: 0,
          waitUntil: () => null,
        );
      }
      return ok;
    } finally {
      _authenticating = false;
      _hiddenAt = null;
    }
  }

  /// Active le verrouillage, ou change le code.
  Future<void> setPin(String pin) async {
    await _store.setPin(pin);
    state = state.copyWith(
      enabled: true,
      locked: false,
      failures: 0,
      waitUntil: () => null,
    );
    unawaited(ref.read(secureWindowProvider).set(true));
  }

  Future<void> disable() async {
    await _store.clear();
    state = state.copyWith(
      enabled: false,
      locked: false,
      biometric: false,
      failures: 0,
      waitUntil: () => null,
    );
    unawaited(ref.read(secureWindowProvider).set(false));
  }

  /// Active la biométrie après une reconnaissance réussie.
  Future<bool> setBiometric(bool value, String reason) async {
    if (value) {
      _authenticating = true;
      try {
        if (!await ref.read(biometricServiceProvider).authenticate(reason)) {
          return false;
        }
      } finally {
        _authenticating = false;
        _hiddenAt = null;
      }
    }
    await _store.setBiometric(value);
    state = state.copyWith(biometric: value);
    return true;
  }

  Future<void> setDelay(LockDelay delay) async {
    await _store.setDelay(delay);
    state = state.copyWith(delay: delay);
  }
}

final lockControllerProvider = NotifierProvider<LockController, LockState>(
  LockController.new,
);
