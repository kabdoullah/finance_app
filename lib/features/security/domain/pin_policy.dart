/// Règles du code PIN, sans dépendance (testables).
abstract final class PinPolicy {
  static const length = 4;

  /// Essais ratés avant une attente.
  static const attemptsPerSeries = 5;

  static const firstWait = Duration(seconds: 30);

  /// Attente imposée après [failures] codes faux consécutifs : 30 s après 5,
  /// puis doublée à chaque nouvelle série de 5 (1 min, 2 min…), 1 h au plus.
  static Duration? waitAfter(int failures) {
    if (failures < attemptsPerSeries || failures % attemptsPerSeries != 0) {
      return null;
    }
    final series = failures ~/ attemptsPerSeries;
    final seconds = firstWait.inSeconds << (series - 1).clamp(0, 7);
    return Duration(seconds: seconds.clamp(0, 3600));
  }

  /// Essais restants avant la prochaine attente.
  static int remainingBeforeWait(int failures) =>
      attemptsPerSeries - failures % attemptsPerSeries;

  static bool isWellFormed(String pin) =>
      pin.length == length && RegExp(r'^\d+$').hasMatch(pin);
}

/// Délai « Verrouiller après ».
enum LockDelay {
  immediately(Duration.zero),
  oneMinute(Duration(minutes: 1)),
  fiveMinutes(Duration(minutes: 5));

  const LockDelay(this.duration);

  final Duration duration;
}
