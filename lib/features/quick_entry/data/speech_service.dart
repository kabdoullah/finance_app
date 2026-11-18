import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Disponibilité de la dictée hors ligne (reconnaissance Android sur
/// l'appareil, voir `MainActivity.kt`).
enum SpeechAvailability {
  /// Android < 12 ou aucun service vocal sur l'appareil : clavier seulement.
  unsupported,

  /// Le français n'est pas installé pour la reconnaissance hors connexion.
  missingLanguage,

  /// Le français est en cours de téléchargement.
  downloading,
  ready,

  /// Android ne sait pas répondre (Android 12) : on tente l'écoute.
  unknown,
}

/// Événements d'une écoute.
sealed class SpeechEvent {
  const SpeechEvent();
}

final class SpeechStarted extends SpeechEvent {
  const SpeechStarted();
}

/// Niveau sonore (dB, environ -2 à 10).
final class SpeechLevel extends SpeechEvent {
  const SpeechLevel(this.value);

  final double value;
}

final class SpeechPartial extends SpeechEvent {
  const SpeechPartial(this.text);

  final String text;
}

final class SpeechFinal extends SpeechEvent {
  const SpeechFinal(this.text);

  final String text;
}

final class SpeechError extends SpeechEvent {
  const SpeechError(this.code);

  /// Codes `SpeechRecognizer.ERROR_*` d'Android.
  final int code;

  static const noMatch = 7;
  static const speechTimeout = 6;
  static const permission = 9;
  static const languageNotSupported = 12;
  static const languageUnavailable = 13;

  bool get isNothingHeard => code == noMatch || code == speechTimeout;
  bool get isMissingLanguage =>
      code == languageNotSupported || code == languageUnavailable;
}

/// Pont vers la reconnaissance vocale Android. L'audio ne quitte jamais le
/// téléphone.
class SpeechService {
  SpeechService();

  static const _methods = MethodChannel('finance_app/speech');
  static const _events = EventChannel('finance_app/speech/events');

  late final Stream<SpeechEvent> events = _events.receiveBroadcastStream().map((
    raw,
  ) {
    final event = Map<String, Object?>.from(raw as Map);
    return switch (event['type']) {
      'ready' => const SpeechStarted(),
      'level' => SpeechLevel((event['value']! as num).toDouble()),
      'partial' => SpeechPartial(event['text']! as String),
      'final' => SpeechFinal(event['text']! as String),
      _ => SpeechError((event['code'] as int?) ?? -1),
    };
  });

  Future<SpeechAvailability> availability() async {
    try {
      final value = await _methods.invokeMethod<String>('status');
      return SpeechAvailability.values.firstWhere(
        (a) => a.name == value,
        orElse: () => SpeechAvailability.unsupported,
      );
    } on MissingPluginException {
      return SpeechAvailability.unsupported;
    } on PlatformException {
      return SpeechAvailability.unsupported;
    }
  }

  /// Demande à Android d'installer le français (sans effet sur certaines
  /// surcouches, comme MIUI : l'écran affiche alors les étapes manuelles).
  Future<void> requestFrenchDownload() => _methods.invokeMethod('download');

  Future<bool> requestPermission() async =>
      await _methods.invokeMethod<bool>('requestPermission') ?? false;

  Future<void> start() => _methods.invokeMethod('start');

  /// Termine l'écoute : le résultat final arrive par [events].
  Future<void> stop() => _methods.invokeMethod('stop');

  Future<void> cancel() => _methods.invokeMethod('cancel');
}

final speechServiceProvider = Provider<SpeechService>((ref) => SpeechService());

/// État de la dictée, relu à chaque ouverture d'un écran qui l'affiche.
final speechAvailabilityProvider =
    FutureProvider.autoDispose<SpeechAvailability>(
      (ref) => ref.watch(speechServiceProvider).availability(),
    );
