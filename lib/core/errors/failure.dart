/// Échec attendu d'une opération (validation, élément absent, stockage).
///
/// Les erreurs prévisibles sont des valeurs de retour ([Result]), pas des
/// exceptions : l'appelant est obligé de les traiter (`switch` exhaustif).
sealed class Failure {
  const Failure();
}

/// Données saisies invalides. [errors] est une énumération propre à chaque
/// fonctionnalité (ex. `AccountFieldError`).
final class ValidationFailure<E extends Enum> extends Failure {
  const ValidationFailure(this.errors);

  final Set<E> errors;
}

/// L'élément demandé n'existe pas, ou plus.
final class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

/// Erreur inattendue de la base locale.
final class StorageFailure extends Failure {
  const StorageFailure(this.cause, this.stackTrace);

  final Object cause;
  final StackTrace stackTrace;
}
