import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';

/// Durée moyenne d'un mois, en jours (pour les mois « fractionnaires »).
const _daysPerMonth = 365.25 / 12;

/// Objectif d'épargne. [saved] est calculé (contributions − retraits).
@immutable
class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.target,
    required this.saved,
    required this.createdAt,
    this.targetDate,
  });

  final String id;
  final String name;
  final String iconKey;
  final Money target;

  /// Montant réservé pour l'objectif, sur l'ensemble des comptes.
  final Money saved;

  /// Date cible (date calendaire) ; `null` = sans date.
  final DateTime? targetDate;
  final DateTime createdAt;

  bool get isReached => saved.value >= target.value;

  /// Reste à épargner (jamais négatif).
  Money get left => Money(isReached ? 0 : target.value - saved.value);

  /// Progression de 0 à 1 (plafonnée).
  double get progress =>
      saved.value <= 0 ? 0 : (saved.value / target.value).clamp(0, 1);

  int get percent => saved.value * 100 ~/ target.value;

  /// Jours restants jusqu'à la date cible ; `null` sans date.
  int? daysLeft(DateTime now) {
    final date = targetDate;
    if (date == null) return null;
    return (date.difference(_day(now)).inHours / 24).round();
  }

  bool isOverdue(DateTime now) {
    final days = daysLeft(now);
    return !isReached && days != null && days <= 0;
  }

  /// Effort par mois : reste ÷ mois restants (fractionnaires, au moins un),
  /// arrondi à la centaine supérieure. `null` sans date, si l'objectif est
  /// atteint ou si la date est dépassée.
  Money? perMonth(DateTime now) => _effort(now, _daysPerMonth);

  /// Effort par semaine, même principe.
  Money? perWeek(DateTime now) => _effort(now, 7);

  Money? _effort(DateTime now, double daysPerPeriod) {
    final days = daysLeft(now);
    if (days == null || days <= 0 || isReached) return null;
    final periods = days / daysPerPeriod;
    return roundUpToHundred(
      Money((left.value / (periods < 1 ? 1 : periods)).ceil()),
    );
  }

  /// En retard sur un plan linéaire de la création à la date cible :
  /// l'épargne attendue aujourd'hui est cible × temps écoulé ÷ durée totale.
  bool isLate(DateTime now) {
    final date = targetDate;
    if (date == null || isReached) return false;
    final start = _day(createdAt);
    final total = date.difference(start).inHours;
    if (total <= 0) return true;
    final elapsed = _day(now).difference(start).inHours.clamp(0, total);
    return saved.value * total < target.value * elapsed;
  }

  static DateTime _day(DateTime d) {
    final local = d.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}

/// Arrondi à la centaine supérieure (« ≈ 36 000 FCFA par mois »).
Money roundUpToHundred(Money amount) => Money((amount.value + 99) ~/ 100 * 100);

/// Contribution (réserve de l'argent) ou retrait (libère la réserve).
enum GoalMovementKind {
  contribution('contribution'),
  withdrawal('withdrawal');

  const GoalMovementKind(this.storageValue);

  final String storageValue;

  static GoalMovementKind fromStorage(String value) =>
      values.firstWhere((k) => k.storageValue == value);
}

@immutable
class GoalMovement {
  const GoalMovement({
    required this.id,
    required this.kind,
    required this.amount,
    required this.accountId,
    required this.accountName,
    required this.occurredAt,
  });

  final String id;
  final GoalMovementKind kind;
  final Money amount;
  final String accountId;
  final String accountName;
  final DateTime occurredAt;

  /// Effet sur l'épargne : positif pour une contribution.
  Money get signed =>
      kind == GoalMovementKind.contribution ? amount : Money(-amount.value);
}

/// Vue d'ensemble de la liste (« Mis de côté 315 000 / 850 000 FCFA »).
@immutable
class GoalsSummary {
  const GoalsSummary._(this.saved, this.target, this.inProgress, this.count);

  factory GoalsSummary.of(Iterable<SavingsGoal> goals) {
    var saved = Money.zero;
    var target = Money.zero;
    var inProgress = 0;
    var count = 0;
    for (final g in goals) {
      saved += g.saved;
      target += g.target;
      count++;
      if (!g.isReached) inProgress++;
    }
    return GoalsSummary._(saved, target, inProgress, count);
  }

  final Money saved;
  final Money target;
  final int inProgress;
  final int count;
}
