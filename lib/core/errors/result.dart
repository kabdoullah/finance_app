import 'failure.dart';

export 'failure.dart';

/// Résultat d'une opération qui peut échouer de façon prévisible.
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
