import 'dart:convert';
import 'dart:typed_data';

import '../../../l10n/l10n.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/presentation/transaction_labels.dart';

/// Opérations au format CSV pour Excel ou Google Sheets en français :
/// séparateur « ; », UTF-8 avec BOM (accents lus correctement par Excel),
/// montants entiers signés (dépenses négatives), dates « AAAA-MM-JJ HH:MM ».
Uint8List transactionsCsv(
  List<Transaction> transactions,
  AppLocalizations l10n,
) {
  String cell(String value) {
    final escaped = value.replaceAll('"', '""');
    return RegExp(r'[;"\n\r]').hasMatch(value) ? '"$escaped"' : escaped;
  }

  String two(int n) => n.toString().padLeft(2, '0');
  String date(DateTime d) =>
      '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';

  final rows = [
    [
      l10n.exCsvDate,
      l10n.exCsvKind,
      l10n.exCsvAmount,
      l10n.exCsvCategory,
      l10n.exCsvSubcategory,
      l10n.exCsvAccount,
      l10n.exCsvToAccount,
      l10n.exCsvDescription,
      l10n.exCsvEntry,
    ],
    for (final t in transactions)
      [
        date(t.occurredAt),
        t.kind.label(l10n),
        '${t.kind == TransactionKind.expense ? -t.amount.value : t.amount.value}',
        t.mainCategory?.name ?? '',
        t.parentCategory == null ? '' : (t.category?.name ?? ''),
        t.accountName,
        t.toAccountName ?? '',
        t.description ?? '',
        t.entryMethod.label(l10n),
      ],
  ];
  final text = rows.map((row) => row.map(cell).join(';')).join('\r\n');
  return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode('$text\r\n')]);
}
