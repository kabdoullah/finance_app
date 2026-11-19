import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/categories/domain/category.dart';
import 'package:finance_app/features/export/data/csv_export.dart';
import 'package:finance_app/features/export/data/pdf_statement.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
// Vérifie la couverture de la police, sans équivalent public.
// ignore: implementation_imports
import 'package:pdf/src/pdf/font/ttf_parser.dart';
import 'package:pdf/widgets.dart' as pw;

final _l10n = lookupAppLocalizations(const Locale('fr'));

const _transport = Category(
  id: 'exp.transport',
  name: 'Transport',
  kind: CategoryKind.expense,
  iconKey: 'bus',
);
const _taxi = Category(
  id: 'exp.transport.taxi',
  name: 'Taxi',
  kind: CategoryKind.expense,
  iconKey: 'taxi',
  parentId: 'exp.transport',
);

final _transactions = [
  Transaction(
    id: '1',
    kind: TransactionKind.expense,
    amount: const Money(2500),
    accountId: 'w',
    accountName: 'Wave',
    category: _taxi,
    parentCategory: _transport,
    description: 'Taxi ; "Plateau"',
    occurredAt: DateTime(2026, 11, 14, 8, 5),
    entryMethod: EntryMethod.voice,
  ),
  Transaction(
    id: '2',
    kind: TransactionKind.income,
    amount: const Money(380000),
    accountId: 'e',
    accountName: 'Ecobank',
    occurredAt: DateTime(2026, 11, 1, 9),
    entryMethod: EntryMethod.recurring,
  ),
  Transaction(
    id: '3',
    kind: TransactionKind.transfer,
    amount: const Money(50000),
    accountId: 'e',
    accountName: 'Ecobank',
    toAccountId: 'w',
    toAccountName: 'Wave',
    occurredAt: DateTime(2026, 11, 2, 10),
    entryMethod: EntryMethod.manual,
  ),
];

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  test('CSV : BOM, « ; », dépenses négatives, guillemets échappés', () {
    final bytes = transactionsCsv(_transactions, _l10n);
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    final lines = utf8.decode(bytes.skip(3).toList()).split('\r\n');
    expect(
      lines.first,
      'Date;Type;Montant (FCFA);Catégorie;Sous-catégorie;Compte;'
      'Vers le compte;Description;Saisie',
    );
    expect(
      lines[1],
      '2026-11-14 08:05;Dépense;-2500;Transport;Taxi;Wave;;'
      '"Taxi ; ""Plateau""";${_l10n.entryVoice}',
    );
    expect(lines[2], startsWith('2026-11-01 09:00;Revenu;380000;;;Ecobank;;'));
    expect(lines[3], contains(';50000;;;Ecobank;Wave;'));
    expect(lines.last, isEmpty);
  });

  test('police du relevé : accents, espace des montants, « − », « · »', () {
    final data = File('assets/fonts/Manrope-Regular.ttf').readAsBytesSync();
    final glyphs = TtfParser(data.buffer.asByteData()).charToGlyphIndexMap;
    // Espace des montants : U+00A0 (MoneyFormat), pas l'espace fine U+202F,
    // absente de Manrope.
    for (final c in 'éèàçôû\u00a0\u2212·…'.runes) {
      expect(glyphs.containsKey(c), isTrue, reason: 'U+${c.toRadixString(16)}');
    }
  });

  test('relevé PDF du mois', () async {
    pw.Font font(String file) => pw.Font.ttf(
      File('assets/fonts/$file').readAsBytesSync().buffer.asByteData(),
    );
    final bytes = await monthStatementPdf(
      transactions: _transactions,
      monthLabel: 'novembre 2026',
      now: DateTime(2026, 11, 19, 10, 24),
      fonts: StatementFonts(
        regular: font('Manrope-Regular.ttf'),
        bold: font('Manrope-SemiBold.ttf'),
      ),
      l10n: _l10n,
    );
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(2000));
  });
}
