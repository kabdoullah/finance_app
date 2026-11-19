import 'dart:typed_data';

import 'package:intl/intl.dart' show DateFormat;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/money/money.dart';
import '../../../l10n/l10n.dart';
import '../../transactions/domain/expense_breakdown.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_stats.dart';
import '../../transactions/presentation/transaction_labels.dart';

/// Polices du relevé (Manrope, comme l'application : accents, espaces
/// insécables et signe « − » compris).
class StatementFonts {
  const StatementFonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;
}

/// Relevé d'un mois en PDF : totaux (transferts exclus), répartition des
/// dépenses et liste des opérations, avec les calculs des écrans.
Future<Uint8List> monthStatementPdf({
  required List<Transaction> transactions,
  required String monthLabel,
  required DateTime now,
  required StatementFonts fonts,
  required AppLocalizations l10n,
  String locale = 'fr',
}) {
  final totals = TransactionTotals.of(transactions);
  final breakdown = ExpenseBreakdown.of(transactions);
  final net = totals.income - totals.expense;
  final day = DateFormat('d MMM', locale);
  String fcfa(Money m) => '${MoneyFormat.amount(m)} FCFA';

  const grey = PdfColor.fromInt(0xFF6B6F6A);
  const line = PdfColor.fromInt(0xFFE3E1DA);
  const green = PdfColor.fromInt(0xFF1F4D3A);
  const red = PdfColor.fromInt(0xFFA4442F);

  pw.Widget total(String label, String value, {PdfColor? color}) => pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(color: grey, fontSize: 9)),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(font: fonts.bold, fontSize: 14, color: color),
        ),
      ],
    ),
  );

  final document = pw.Document(
    title: l10n.exPdfTitle(monthLabel),
    creator: l10n.appTitle,
    theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
  );
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(color: grey, fontSize: 8),
        ),
      ),
      build: (context) => [
        pw.Text(
          l10n.exPdfTitle(monthLabel),
          style: pw.TextStyle(font: fonts.bold, fontSize: 20),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          l10n.exPdfGenerated(
            DateFormat('d MMMM y, HH:mm', locale).format(now),
          ),
          style: const pw.TextStyle(color: grey, fontSize: 9),
        ),
        pw.SizedBox(height: 18),
        pw.Row(
          children: [
            total(l10n.exPdfIncome, fcfa(totals.income), color: green),
            total(l10n.exPdfExpenses, fcfa(totals.expense), color: red),
            total(
              l10n.exPdfNet,
              '${net.isNegative ? MoneyFormat.signed(net) : MoneyFormat.amount(net)} FCFA',
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          l10n.exPdfTransfersNote,
          style: const pw.TextStyle(color: grey, fontSize: 8),
        ),
        if (!breakdown.isEmpty) ...[
          pw.SizedBox(height: 18),
          pw.Text(
            l10n.exPdfBreakdown,
            style: pw.TextStyle(font: fonts.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 6),
          for (final share in breakdown.shares)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(share.category?.name ?? l10n.exPdfOthers),
                  ),
                  pw.SizedBox(
                    width: 40,
                    child: pw.Text(
                      '${share.percent} %',
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(color: grey),
                    ),
                  ),
                  pw.SizedBox(
                    width: 100,
                    child: pw.Text(
                      fcfa(share.amount),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
        ],
        pw.SizedBox(height: 18),
        pw.Text(
          l10n.exPdfOperations(transactions.length),
          style: pw.TextStyle(font: fonts.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: line, width: 0.5),
          ),
          headerStyle: pw.TextStyle(font: fonts.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: grey, width: 0.5)),
          ),
          columnWidths: const {
            0: pw.FixedColumnWidth(48),
            1: pw.FlexColumnWidth(3),
            2: pw.FlexColumnWidth(3),
            3: pw.FixedColumnWidth(80),
          },
          cellAlignments: const {3: pw.Alignment.centerRight},
          headers: [
            l10n.exCsvDate,
            l10n.exCsvDescription,
            l10n.exCsvCategory,
            l10n.exCsvAmount,
          ],
          data: [
            for (final t in transactions)
              [
                day.format(t.occurredAt),
                t.title(l10n),
                t.meta(l10n),
                t.signedAmount,
              ],
          ],
        ),
      ],
    ),
  );
  return document.save();
}
