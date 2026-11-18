import 'package:drift/drift.dart';

import '../../../core/clock.dart';
import '../../../core/database/app_database.dart';
import '../../../core/time/calendar_date.dart';
import '../domain/forecast.dart';

/// Historique des opérations agrégé pour le moteur de prévision.
class ForecastRepository {
  ForecastRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  /// Jours d'historique du solde affichés au maximum sur le graphique.
  static const _netDays = 14;

  /// Réévalué à chaque changement des opérations.
  Stream<SpendingHistory> watchHistory() {
    final today = CalendarDate.of(_clock());
    final from = DateTime(
      today.year,
      today.month,
      today.day - Forecast.variableWindowDays + 1,
    );
    final netFrom = DateTime(today.year, today.month, today.day - _netDays);
    return _db
        .customSelect(
          'SELECT occurred_at, kind, amount, recurring_id FROM transactions '
          "WHERE kind <> 'transfer' AND occurred_at >= ?",
          variables: [Variable.withInt(_ms(from))],
          readsFrom: {_db.transactions},
        )
        .watch()
        .asyncMap((rows) async {
          final first = await _db
              .customSelect(
                'SELECT MIN(occurred_at) AS first FROM transactions',
                readsFrom: {_db.transactions},
              )
              .getSingle();
          final firstMs = first.readNullable<int>('first');
          final variable = <DateTime, int>{};
          final net = <DateTime, int>{};
          for (final row in rows) {
            final day = CalendarDate.of(
              DateTime.fromMillisecondsSinceEpoch(
                row.read<int>('occurred_at'),
                isUtc: true,
              ).toLocal(),
            );
            final amount = row.read<int>('amount');
            final isExpense = row.read<String>('kind') == 'expense';
            if (isExpense && row.readNullable<String>('recurring_id') == null) {
              variable[day] = (variable[day] ?? 0) + amount;
            }
            if (!day.isBefore(netFrom)) {
              net[day] = (net[day] ?? 0) + (isExpense ? -amount : amount);
            }
          }
          return SpendingHistory(
            firstDay: firstMs == null
                ? null
                : CalendarDate.of(
                    DateTime.fromMillisecondsSinceEpoch(
                      firstMs,
                      isUtc: true,
                    ).toLocal(),
                  ),
            variableExpenseByDay: variable,
            netByDay: net,
          );
        });
  }

  static int _ms(DateTime date) => date.toUtc().millisecondsSinceEpoch;
}
