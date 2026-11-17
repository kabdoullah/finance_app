import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/clock.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/formatting/text_search.dart';
import '../../../core/money/money.dart';
import '../../../core/time/month.dart';
import '../../../core/widgets/segmented_choice.dart';
import '../../../l10n/l10n.dart';
import '../domain/transaction.dart';
import '../domain/transaction_stats.dart';
import 'new_operation_sheet.dart';
import 'transaction_labels.dart';
import 'transactions_providers.dart';

/// Onglet Transactions : recherche, type, mois, opérations groupées par jour.
class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _search = TextEditingController();
  late Month _month = Month.of(ref.read(clockProvider)());

  /// `null` = tous les types.
  TransactionKind? _kind;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Transaction t, AppLocalizations l10n) =>
      (_kind == null || t.kind == _kind) &&
      TextSearch.matches(_search.text, [
        t.description,
        t.category?.name,
        t.mainCategory?.name,
        t.accountName,
        t.toAccountName,
        t.title(l10n),
      ]);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final relative = RelativeDate(
      l10n,
      Localizations.localeOf(context).toLanguageTag(),
      ref.watch(clockProvider)(),
    );
    final hasAny = ref.watch(hasTransactionsProvider).value;
    final monthTransactions = ref
        .watch(monthTransactionsProvider(_month))
        .value;

    final header = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                l10n.txListTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.accountsTitle,
            onPressed: () => context.go(AppRoutes.accounts),
            icon: const Icon(AppIcons.wallet, size: 20),
          ),
        ],
      ),
    );

    // Aucune opération du tout : état vide de la maquette.
    if (hasAny == false) {
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            children: [header, const _EmptyState()],
          ),
        ),
      );
    }

    final visible = [
      for (final t in monthTransactions ?? const <Transaction>[])
        if (_matches(t, l10n)) t,
    ];
    final totals = TransactionTotals.of(visible);
    final query = _search.text.trim();
    final monthName = relative.month(_month);

    return Scaffold(
      floatingActionButton: const AddOperationButton(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
          children: [
            header,
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.txSearchHint,
                prefixIcon: Icon(
                  AppIcons.magnifyingGlass,
                  size: 18,
                  color: colors.inkSecondary,
                ),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.txClearSearch,
                        onPressed: _search.clear,
                        icon: const Icon(AppIcons.xBold, size: 14),
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => _chooseMonth(relative),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.only(left: 14, right: 12),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    Text(RelativeDate.capitalize(monthName)),
                    Icon(
                      AppIcons.caretDownBold,
                      size: 11,
                      color: colors.inkTertiary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SegmentedChoice<TransactionKind?>(
              options: [
                (null, l10n.txFilterAll),
                (TransactionKind.income, l10n.txFilterIncome),
                (TransactionKind.expense, l10n.txFilterExpense),
                (TransactionKind.transfer, l10n.txFilterTransfer),
              ],
              selected: _kind,
              onChanged: (kind) => setState(() => _kind = kind),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.txCountSummary(visible.length),
                    style: TextStyle(fontSize: 13, color: colors.inkSecondary),
                  ),
                ),
                Text(
                  MoneyFormat.signed(totals.income),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.positive,
                  ),
                ),
                Text(
                  ' · ',
                  style: TextStyle(fontSize: 13, color: colors.inkSecondary),
                ),
                Text(
                  MoneyFormat.signed(-totals.expense),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (monthTransactions != null && visible.isEmpty)
              query.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        l10n.txMonthEmpty(monthName),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.inkSecondary),
                      ),
                    )
                  : _NoResult(
                      query: query,
                      month: monthName,
                      onClear: _search.clear,
                    ),
            for (final (day, items) in groupByDay(visible)) ...[
              DayHeader(relative.header(day)),
              for (final t in items)
                TransactionTile(
                  transaction: t,
                  onTap: () => context.go(AppRoutes.transactionDetail(t.id)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Les 12 derniers mois.
  Future<void> _chooseMonth(RelativeDate relative) async {
    final current = Month.of(ref.read(clockProvider)());
    final months = [
      for (var m = current, i = 0; i < 12; m = m.previous, i++) m,
    ];
    final picked = await showModalBottomSheet<Month>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                sheetContext.l10n.txChooseMonth,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final m in months)
              ListTile(
                title: Text(RelativeDate.capitalize(relative.month(m))),
                trailing: m == _month
                    ? Icon(
                        AppIcons.checkBold,
                        size: 16,
                        color: sheetContext.colors.primary,
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(m),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _month = picked);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        spacing: 12,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primarySoft,
            ),
            child: Icon(AppIcons.tray, size: 28, color: colors.onPrimarySoft),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.txEmptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          Text(
            l10n.txEmptyBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: colors.inkSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => showNewOperationSheet(context),
              icon: const Icon(AppIcons.plusBold, size: 18),
              label: Text(l10n.txEmptyAction),
            ),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.assistant),
            child: Text(l10n.dashboardCopilotAction),
          ),
        ],
      ),
    );
  }
}

class _NoResult extends StatelessWidget {
  const _NoResult({
    required this.query,
    required this.month,
    required this.onClear,
  });

  final String query;
  final String month;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        spacing: 10,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.chip,
            ),
            child: Icon(
              AppIcons.magnifyingGlass,
              size: 24,
              color: colors.inkSecondary,
            ),
          ),
          Text(
            l10n.txNoResultTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          Text(
            l10n.txNoResultBody(query, month),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colors.inkSecondary,
            ),
          ),
          OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            child: Text(l10n.txClearSearch),
          ),
        ],
      ),
    );
  }
}
