import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Branche les gestionnaires d'erreurs globaux (framework + asynchrones).
///
/// Journal local uniquement : aucune donnée ne quitte l'appareil.
void installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _log(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    _log(error, stack);
    return true;
  };
}

void _log(Object error, StackTrace? stack) {
  developer.log(
    'Erreur non gérée',
    name: 'finance_app',
    error: error,
    stackTrace: stack,
  );
}

/// Erreur rattrapée mais à garder dans le journal local (ex. échec de
/// chargement du modèle IA).
void reportError(Object error, StackTrace stack) => _log(error, stack);
