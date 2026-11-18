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
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/account_labels.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_providers.dart';
import '../../categories/presentation/category_icons.dart';
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

  /// `null` = tous les comptes. Un transfert correspond s'il touche le compte.
  String? _accountId;

  /// `null` = toutes les catégories (filtre sur la catégorie principale).
  String? _categoryId;

  bool get _hasFilters => _accountId != null || _categoryId != null;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    final requested = ref.read(transactionsCategoryRequestProvider);
    if (requested != null) {
      _categoryId = requested;
      Future.microtask(
        () => ref.read(transactionsCategoryRequestProvider.notifier).clear(),
      );
    }
  }

  /// Filtre demandé depuis un budget : catégorie, mois en cours, tous comptes.
  void _applyRequest(String categoryId) {
    setState(() {
      _categoryId = categoryId;
      _accountId = null;
      _kind = null;
      _search.clear();
      _month = Month.of(ref.read(clockProvider)());
    });
    ref.read(transactionsCategoryRequestProvider.notifier).clear();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Transaction t, AppLocalizations l10n) =>
      (_kind == null || t.kind == _kind) &&
      (_accountId == null || t.involves(_accountId!)) &&
      (_categoryId == null || t.mainCategory?.id == _categoryId) &&
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
    // Onglet déjà ouvert : applique une demande venue d'un budget.
    ref.listen(transactionsCategoryRequestProvider, (_, requested) {
      if (requested != null) _applyRequest(requested);
    });
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
            tooltip: l10n.recurringTitle,
            onPressed: () => context.go(AppRoutes.recurring),
            icon: const Icon(AppIcons.repeat, size: 20),
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
            // Filtres de la maquette : période, compte, catégorie.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                spacing: 8,
                children: [
                  _FilterChip(
                    label: RelativeDate.capitalize(monthName),
                    onTap: () => _chooseMonth(relative),
                  ),
                  _FilterChip(
                    label: _accountLabel(l10n) ?? l10n.txAllAccounts,
                    active: _accountId != null,
                    onTap: _chooseAccount,
                  ),
                  _FilterChip(
                    label: _categoryLabel() ?? l10n.txAllCategories,
                    active: _categoryId != null,
                    onTap: _chooseCategory,
                  ),
                ],
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
                      child: Column(
                        spacing: 8,
                        children: [
                          Text(
                            _hasFilters
                                ? l10n.txNoFilterMatch(monthName)
                                : l10n.txMonthEmpty(monthName),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.inkSecondary),
                          ),
                          if (_hasFilters)
                            TextButton(
                              onPressed: () => setState(() {
                                _accountId = null;
                                _categoryId = null;
                              }),
                              child: Text(l10n.txResetFilters),
                            ),
                        ],
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

  /// Comptes actifs puis archivés : une opération peut appartenir à un compte
  /// archivé.
  List<Account> _allAccounts() => [
    ...?ref.read(activeAccountsProvider).value,
    ...?ref.read(archivedAccountsProvider).value,
  ];

  String? _accountLabel(AppLocalizations l10n) {
    final account = [
      ...?ref.watch(activeAccountsProvider).value,
      ...?ref.watch(archivedAccountsProvider).value,
    ].where((a) => a.id == _accountId).firstOrNull;
    if (account == null) return null;
    return account.isArchived
        ? l10n.txArchivedAccount(account.name)
        : account.name;
  }

  String? _categoryLabel() => [
    ...?ref.watch(categoryGroupsProvider(CategoryKind.expense)).value,
    ...?ref.watch(categoryGroupsProvider(CategoryKind.income)).value,
  ].where((g) => g.category.id == _categoryId).firstOrNull?.category.name;

  /// Les 12 derniers mois.
  Future<void> _chooseMonth(RelativeDate relative) async {
    final current = Month.of(ref.read(clockProvider)());
    final picked = await _showChoices<Month>(
      title: context.l10n.txChooseMonth,
      selected: _month,
      options: [
        for (var m = current, i = 0; i < 12; m = m.previous, i++)
          _Choice(m, RelativeDate.capitalize(relative.month(m))),
      ],
    );
    if (picked != null) setState(() => _month = picked.$1);
  }

  Future<void> _chooseAccount() async {
    final l10n = context.l10n;
    final picked = await _showChoices<String?>(
      title: l10n.txChooseAccount,
      selected: _accountId,
      options: [
        _Choice(null, l10n.txAllAccounts),
        for (final account in _allAccounts())
          _Choice(
            account.id,
            account.isArchived
                ? l10n.txArchivedAccount(account.name)
                : account.name,
            icon: account.type.icon,
          ),
      ],
    );
    if (picked != null) setState(() => _accountId = picked.$1);
  }

  Future<void> _chooseCategory() async {
    // On attend les catégories : la feuille ne doit jamais s'ouvrir vide.
    final expense = await ref.read(
      categoryGroupsProvider(CategoryKind.expense).future,
    );
    final income = await ref.read(
      categoryGroupsProvider(CategoryKind.income).future,
    );
    if (!mounted) return;
    final l10n = context.l10n;
    List<_Choice<String?>> section(
      List<CategoryGroup> groups,
      String heading,
    ) => [
      _Choice.heading(heading),
      for (final group in groups)
        if (!group.category.isHidden || group.category.id == _categoryId)
          _Choice(
            group.category.id,
            group.category.name,
            icon: categoryIcon(group.category.iconKey),
          ),
    ];
    final picked = await _showChoices<String?>(
      title: l10n.txChooseCategory,
      selected: _categoryId,
      options: [
        _Choice(null, l10n.txAllCategories),
        ...section(expense, l10n.txFilterExpenseSection),
        ...section(income, l10n.txFilterIncomeSection),
      ],
    );
    if (picked != null) setState(() => _categoryId = picked.$1);
  }

  /// Feuille de choix. Retourne `(valeur,)` (la valeur peut être `null` pour
  /// « Tous »), ou `null` si la feuille est fermée sans choix.
  Future<(T,)?> _showChoices<T>({
    required String title,
    required T selected,
    required List<_Choice<T>> options,
  }) async {
    final result = await showModalBottomSheet<(T,)>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (sheetContext) {
        final colors = sheetContext.colors;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                for (final option in options)
                  if (option.isHeading)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
                      child: Text(
                        option.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: colors.inkTertiary,
                        ),
                      ),
                    )
                  else
                    ListTile(
                      leading: option.icon == null
                          ? null
                          : Icon(option.icon, size: 20, color: colors.ink),
                      title: Text(option.label),
                      trailing: option.value == selected
                          ? Icon(
                              AppIcons.checkBold,
                              size: 16,
                              color: colors.primary,
                            )
                          : null,
                      onTap: () =>
                          Navigator.of(sheetContext).pop((option.value,)),
                    ),
              ],
            ),
          ),
        );
      },
    );
    return mounted ? result : null;
  }
}

/// Option d'une feuille de choix (ou intertitre de section).
class _Choice<T> {
  const _Choice(this.value, this.label, {this.icon}) : isHeading = false;

  const _Choice.heading(this.label)
    : value = null as T,
      icon = null,
      isHeading = true;

  final T value;
  final String label;
  final IconData? icon;
  final bool isHeading;
}

/// Puce de filtre des maquettes (« Novembre ▾ », « Tous les comptes ▾ »),
/// mise en avant quand un filtre est actif.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = StadiumBorder(
      side: BorderSide(color: active ? colors.primary : colors.line),
    );
    final foreground = active ? colors.onPrimarySoft : colors.ink;
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: active ? colors.primarySoft : colors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.only(left: 14, right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                  Icon(
                    AppIcons.caretDownBold,
                    size: 11,
                    color: active ? foreground : colors.inkTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
