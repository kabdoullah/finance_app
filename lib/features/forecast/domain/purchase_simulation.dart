import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import 'forecast.dart';

enum PurchaseVerdict { possible, tight, discouraged }

/// « Puis-je acheter … ? » : la prévision à 30 jours, sur le disponible
/// (solde − réserves des objectifs), moins le prix à partir du jour choisi.
/// Pure hypothèse : rien n'est enregistré.
@immutable
class PurchaseSimulation {
  const PurchaseSimulation._({
    required this.verdict,
    required this.lowest,
    required this.lowestDate,
    required this.negativeOn,
    required this.endBalance,
    required this.endWithout,
    required this.endDate,
  });

  /// [forecast] : prévision à 30 jours. [reserved] : total réservé aux
  /// objectifs. [savingsUsed] : épargne d'un objectif utilisée pour l'achat.
  /// [purchaseDay] : 0 = aujourd'hui.
  factory PurchaseSimulation.compute({
    required Forecast forecast,
    required Money reserved,
    required Money price,
    required int purchaseDay,
    Money savingsUsed = Money.zero,
  }) {
    final points = forecast.points;
    final last = points.length - 1;
    final day = purchaseDay.clamp(0, last);
    final cost = price.value > savingsUsed.value
        ? price.value - savingsUsed.value
        : 0;
    // Disponible prévu sans achat, puis avec.
    int without(int d) => points[d].value - reserved.value;
    int withPurchase(int d) => without(d) - (d >= day ? cost : 0);

    var lowestIndex = day;
    int? negativeIndex;
    for (var d = day; d <= last; d++) {
      if (withPurchase(d) < withPurchase(lowestIndex)) lowestIndex = d;
      if (negativeIndex == null && withPurchase(d) < 0) negativeIndex = d;
    }
    final lowest = withPurchase(lowestIndex);
    final margin = forecast.dailyVariable.value * Forecast.lowBalanceDays;
    final verdict = lowest < 0
        ? PurchaseVerdict.discouraged
        : lowest < margin
        ? PurchaseVerdict.tight
        : PurchaseVerdict.possible;

    DateTime at(int d) => DateTime(
      forecast.today.year,
      forecast.today.month,
      forecast.today.day + d,
    );
    return PurchaseSimulation._(
      verdict: verdict,
      lowest: _round(lowest),
      lowestDate: at(lowestIndex),
      negativeOn: negativeIndex == null ? null : at(negativeIndex),
      endBalance: _round(withPurchase(last)),
      endWithout: _round(without(last)),
      endDate: at(last),
    );
  }

  final PurchaseVerdict verdict;

  /// Disponible le plus bas après l'achat (arrondi au millier) et sa date.
  final Money lowest;
  final DateTime lowestDate;

  /// Premier jour sous zéro, le cas échéant.
  final DateTime? negativeOn;

  /// Disponible en fin de période, avec et sans l'achat.
  final Money endBalance;
  final Money endWithout;
  final DateTime endDate;

  static Money _round(int value) => Money((value / 1000).round() * 1000);
}
