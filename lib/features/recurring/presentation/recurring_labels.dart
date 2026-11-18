import 'package:intl/intl.dart';

import '../../../core/formatting/date_format.dart';
import '../../../core/money/money.dart';
import '../../../l10n/l10n.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/recurrence.dart';
import '../domain/recurring_operation.dart';

/// Libellés des opérations récurrentes (maquettes Recurrentes et
/// Recurrente-Creer).
extension RecurrenceLabels on Recurrence {
  /// « Chaque samedi », « Chaque mois, le 25 », « Chaque année, le 25 nov. »
  String meta(AppLocalizations l10n, String locale) => switch (frequency) {
    RecurrenceFrequency.week => l10n.recurringMetaWeek(_weekday(locale)),
    RecurrenceFrequency.month => l10n.recurringMetaMonth(_day),
    RecurrenceFrequency.year => l10n.recurringMetaYear(
      AppDateFormat.dayMonth(start, locale),
    ),
  };

  /// Ligne « Échéance » du formulaire : « Le 25 de chaque mois »…
  String dueLabel(AppLocalizations l10n, String locale) => switch (frequency) {
    RecurrenceFrequency.week => l10n.recurringDueWeek(_weekday(locale)),
    RecurrenceFrequency.month => l10n.recurringDueMonth(_day),
    RecurrenceFrequency.year => l10n.recurringDueYear(
      '$_day ${DateFormat('MMMM', locale).format(start)}',
    ),
  };

  String _weekday(String locale) => DateFormat('EEEE', locale).format(start);

  String get _day => start.day == 1 ? '1er' : '${start.day}';
}

extension RecurringFrequencyLabels on RecurrenceFrequency {
  String label(AppLocalizations l10n) => switch (this) {
    RecurrenceFrequency.week => l10n.recurringFreqWeek,
    RecurrenceFrequency.month => l10n.recurringFreqMonth,
    RecurrenceFrequency.year => l10n.recurringFreqYear,
  };

  /// « Pas ce mois-ci » et ses variantes.
  String skipLabel(AppLocalizations l10n) => switch (this) {
    RecurrenceFrequency.week => l10n.recurringSkipWeek,
    RecurrenceFrequency.month => l10n.recurringSkipMonth,
    RecurrenceFrequency.year => l10n.recurringSkipYear,
  };
}

extension RecurringOperationLabels on RecurringOperation {
  /// « +380 000 », « −12 500 », « ≈ −14 000 » (montant estimé).
  String get signedAmount =>
      signedRecurringAmount(kind, amount, isVariable: isVariable);
}

String signedRecurringAmount(
  TransactionKind kind,
  Money amount, {
  required bool isVariable,
}) {
  final signed = MoneyFormat.signed(
    kind == TransactionKind.income ? amount : Money(-amount.value),
  );
  return isVariable ? '≈ $signed' : signed;
}
