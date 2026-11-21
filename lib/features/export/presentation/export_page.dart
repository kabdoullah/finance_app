import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/clock.dart';
import '../../../core/errors/error_reporter.dart';
import '../../../core/files/file_output.dart';
import '../../../core/time/month.dart';
import '../../../core/widgets/segmented_choice.dart';
import '../../../l10n/l10n.dart';
import '../../settings/presentation/settings_providers.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../data/csv_export.dart';
import '../data/pdf_statement.dart';

enum _Format { csv, pdf }

/// « Exporter mes données » : toutes les opérations en CSV, ou le relevé
/// d'un mois en PDF, enregistrés ou partagés. Fichiers non chiffrés.
class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  _Format _format = _Format.csv;
  late Month _month = ref.read(monthOfProvider)(ref.read(clockProvider)());
  bool _busy = false;

  /// Fichier à produire (nom, contenu, type), ou `null` si rien à exporter.
  Future<(String, Uint8List, String)?> _build() async {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final repository = ref.read(transactionsRepositoryProvider);
    final now = ref.read(clockProvider)();
    String two(int n) => n.toString().padLeft(2, '0');
    switch (_format) {
      case _Format.csv:
        final all = await repository.all();
        if (all.isEmpty) return null;
        return (
          'finao-operations-${now.year}-${two(now.month)}-'
              '${two(now.day)}.csv',
          transactionsCsv(all, l10n),
          'text/csv',
        );
      case _Format.pdf:
        final month = await repository.watchMonth(_month).first;
        if (month.isEmpty) return null;
        Future<pw.Font> font(String file) async =>
            pw.Font.ttf(await rootBundle.load('assets/fonts/$file'));
        return (
          'finao-releve-${_month.year}-${two(_month.month)}.pdf',
          await monthStatementPdf(
            transactions: month,
            monthLabel: DateFormat('MMMM y', locale).format(_month.start),
            now: now,
            fonts: StatementFonts(
              regular: await font('Manrope-Regular.ttf'),
              bold: await font('Manrope-SemiBold.ttf'),
            ),
            l10n: l10n,
            locale: locale,
          ),
          'application/pdf',
        );
    }
  }

  Future<void> _export({required bool share}) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final output = ref.read(fileOutputProvider);
    setState(() => _busy = true);
    try {
      final file = await _build();
      if (file == null) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.exEmpty)));
        return;
      }
      final (name, bytes, mime) = file;
      if (share) {
        await output.share(name, bytes, mime);
      } else if (await output.save(name, bytes, mime)) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.exSaved)));
      }
    } on Object catch (error, stack) {
      reportError(error, stack);
      messenger.showSnackBar(SnackBar(content: Text(l10n.exFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final current = ref.watch(monthOfProvider)(ref.watch(clockProvider)());
    final months = [current];
    while (months.length < 12) {
      months.add(months.last.previous);
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.exTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          SegmentedChoice<_Format>(
            options: const [(_Format.csv, 'CSV'), (_Format.pdf, 'PDF')],
            selected: _format,
            onChanged: (f) => setState(() => _format = f),
          ),
          const SizedBox(height: 16),
          Text(
            _format == _Format.csv ? l10n.exCsv : l10n.exPdf,
            style: AppText.subtitle,
          ),
          Text(
            _format == _Format.csv ? l10n.exCsvHint : l10n.exPdfHint,
            style: AppText.bodySmall.copyWith(color: colors.inkSecondary),
          ),
          if (_format == _Format.pdf) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<Month>(
              initialValue: _month,
              decoration: InputDecoration(labelText: l10n.exMonth),
              items: [
                for (final m in months)
                  DropdownMenuItem(
                    value: m,
                    child: Text(DateFormat('MMMM y', locale).format(m.start)),
                  ),
              ],
              onChanged: (m) => setState(() => _month = m ?? _month),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.warningSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Icon(
                  AppIcons.warningCircleBold,
                  size: 18,
                  color: colors.warning,
                ),
                Expanded(
                  child: Text(l10n.exWarning, style: AppText.bodySmall.prose),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : () => _export(share: false),
            child: Text(l10n.exSave),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : () => _export(share: true),
            child: Text(l10n.exShare),
          ),
        ],
      ),
    );
  }
}
