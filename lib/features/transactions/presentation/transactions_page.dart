import 'dart:async';

import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/motion.dart';
import '../../../core/clock.dart';
import '../../../core/errors/result.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/formatting/text_search.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/segmented_choice.dart';
import '../../../l10n/l10n.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_providers.dart';
import '../../planned/domain/month_spending.dart';
import '../../planned/domain/planned_expense.dart';
import '../../planned/presentation/planned_labels.dart';
import '../../planned/presentation/planned_providers.dart';
import '../../planned/presentation/spending_calendar.dart';
import '../../settings/presentation/settings_providers.dart';
import '../domain/transaction.dart';
import '../domain/transaction_period.dart';
import 'new_operation_sheet.dart';
import 'transaction_labels.dart';
import 'transactions_providers.dart';
import 'transactions_sheets.dart';

/// Statut affiché : tout, payées seulement, à payer, en retard.
enum _Status { all, paid, planned, late }

/// Onglet Transactions (maquette Transactions) : période (jour, semaine,
/// mois budgétaire, dates choisies), résumé, statuts, filtres, dépenses à
/// payer puis opérations groupées par jour.
class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _search = TextEditingController();
  bool _searchOpen = false;
  late TransactionPeriod _period = _currentMonth();
  _Status _status = _Status.all;
  TransactionFilters _filters = const TransactionFilters();

  /// Opérations glissées hors de la liste, en cours de suppression.
  final Set<String> _removing = {};

  /// Opérations déjà affichées pour la même sélection : les autres
  /// (nouvelles) glissent dans la liste.
  Set<String>? _known;
  Object? _knownSelection;

  DateTime get _now => ref.read(clockProvider)();

  TransactionPeriod _currentMonth() =>
      TransactionPeriod.month(ref.read(monthOfProvider)(_now));

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    final month = ref.read(transactionsMonthRequestProvider);
    if (month != null) {
      _period = TransactionPeriod.month(month);
      Future.microtask(
        () => ref.read(transactionsMonthRequestProvider.notifier).clear(),
      );
    }
    final requested = ref.read(transactionsCategoryRequestProvider);
    if (requested != null) {
      _filters = TransactionFilters(categoryId: requested);
      Future.microtask(
        () => ref.read(transactionsCategoryRequestProvider.notifier).clear(),
      );
    }
  }

  /// Filtre demandé depuis un budget : catégorie, mois en cours, tous
  /// comptes.
  void _applyRequest(String categoryId) {
    setState(() {
      _filters = TransactionFilters(categoryId: categoryId);
      _status = _Status.all;
      _closeSearch();
      _period = _currentMonth();
    });
    ref.read(transactionsCategoryRequestProvider.notifier).clear();
  }

  void _closeSearch() {
    _search.clear();
    _searchOpen = false;
  }

  void _resetAll() => setState(() {
    _filters = const TransactionFilters();
    _status = _Status.all;
    _closeSearch();
  });

  /// Glisser pour supprimer : la ligne se replie, « Annuler » la remet.
  Future<void> _swipeDelete(Transaction t) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _removing.add(t.id));
    unawaited(Haptics.medium());
    final repository = ref.read(transactionsRepositoryProvider);
    final result = await repository.delete(t.id);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                l10n.txSwipeDeleted(
                  t.kind == TransactionKind.transfer
                      ? MoneyFormat.amount(t.amount)
                      : t.signedAmount,
                  t.title(l10n),
                ),
              ),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: l10n.cancel,
                onPressed: () async {
                  await repository.restore(value);
                  if (mounted) setState(() => _removing.remove(t.id));
                },
              ),
            ),
          );
      case Err():
        setState(() => _removing.remove(t.id));
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(
    Transaction t,
    AppLocalizations l10n,
    TransactionFilters filters,
  ) =>
      (filters.kind == null || t.kind == filters.kind) &&
      (filters.accountId == null || t.involves(filters.accountId!)) &&
      (filters.categoryId == null ||
          t.mainCategory?.id == filters.categoryId) &&
      TextSearch.matches(_search.text, [
        t.description,
        t.category?.name,
        t.mainCategory?.name,
        t.accountName,
        t.toAccountName,
        t.title(l10n),
      ]);

  /// Dépense à payer de la période qui passe les filtres (une dépense :
  /// visible pour « Tout » et « Dépenses »).
  bool _matchesDue(DueItem d, TransactionFilters filters) =>
      _period.contains(d.date) &&
      (filters.kind == null || filters.kind == TransactionKind.expense) &&
      (filters.accountId == null || d.accountId == filters.accountId) &&
      (filters.categoryId == null || d.category.id == filters.categoryId) &&
      TextSearch.matches(_search.text, [
        d.name,
        d.category.name,
        d.accountName,
      ]);

  Future<void> _choosePeriod() async {
    final picked = await showPeriodPicker(
      context,
      initial: _period,
      now: _now,
      monthOf: ref.read(monthOfProvider),
    );
    if (picked != null && mounted) setState(() => _period = picked);
  }

  void _setSpan(PeriodSpan span) {
    if (span == PeriodSpan.custom) {
      _choosePeriod();
      return;
    }
    final today = CalendarDate.of(_now);
    setState(
      () => _period = _period.withSpan(
        span,
        anchor: _period.contains(today) ? today : _period.start,
        monthOf: ref.read(monthOfProvider),
      ),
    );
  }

  String _periodLabel(RelativeDate relative) {
    String short(DateTime d) => AppDateFormat.dayMonth(d, relative.locale);
    return switch (_period.span) {
      PeriodSpan.day => relative.header(_period.start),
      PeriodSpan.month => spendingMonthLabel(relative, _period.month!),
      PeriodSpan.week || PeriodSpan.custom =>
        _period.start == _period.last
            ? relative.header(_period.start)
            : relative.l10n.txPeriodRange(
                short(_period.last),
                short(_period.start),
              ),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Début du mois budgétaire changé : retour au mois en cours.
    ref.listen(budgetMonthStartProvider, (_, _) {
      setState(() => _period = _currentMonth());
    });
    // Onglet déjà ouvert : mois demandé depuis Dépenses du mois.
    ref.listen(transactionsMonthRequestProvider, (_, month) {
      if (month == null) return;
      setState(() => _period = TransactionPeriod.month(month));
      ref.read(transactionsMonthRequestProvider.notifier).clear();
    });
    // Onglet déjà ouvert : applique une demande venue d'un budget.
    ref.listen(transactionsCategoryRequestProvider, (_, requested) {
      if (requested != null) _applyRequest(requested);
    });
    final colors = context.colors;
    final l10n = context.l10n;
    final now = ref.watch(clockProvider)();
    final relative = RelativeDate(
      l10n,
      Localizations.localeOf(context).toLanguageTag(),
      now,
    );
    final hasAny = ref.watch(hasTransactionsProvider).value;
    final hasPlanned =
        ref.watch(plannedExpensesProvider).value?.isNotEmpty ?? false;
    final transactions = ref
        .watch(periodTransactionsProvider((_period.start, _period.end)))
        .value;
    final dues = ref.watch(duesProvider);
    final expenseGroups =
        ref.watch(categoryGroupsProvider(CategoryKind.expense)).value ??
        const [];
    final incomeGroups =
        ref.watch(categoryGroupsProvider(CategoryKind.income)).value ??
        const [];
    final accounts = [
      ...?ref.watch(activeAccountsProvider).value,
      ...?ref.watch(archivedAccountsProvider).value,
    ];

    final header = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(l10n.txListTitle, style: AppText.screenTitle),
            ),
          ),
          if (hasAny != false || hasPlanned)
            IconButton(
              tooltip: _searchOpen ? l10n.txSearchClose : l10n.txSearchOpen,
              onPressed: () => setState(
                () => _searchOpen ? _closeSearch() : _searchOpen = true,
              ),
              icon: Icon(
                _searchOpen ? AppIcons.xBold : AppIcons.magnifyingGlass,
                size: 20,
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

    // Premier lancement : rien à lister, ni opération ni dépense planifiée.
    if (hasAny == false && !hasPlanned) {
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              12,
              AppSpacing.gutter,
              40,
            ),
            children: [
              header,
              _EmptyState(now: now),
            ],
          ),
        ),
      );
    }

    final loading = transactions == null || dues == null;
    final periodDues = [
      for (final d in dues ?? const <DueItem>[])
        if (_matchesDue(d, _filters)) d,
    ];
    final late = [
      for (final d in periodDues)
        if (d.statusOn(now) == PlannedStatus.late) d,
    ];
    final upcoming = [
      for (final d in periodDues)
        if (d.statusOn(now) == PlannedStatus.planned) d,
    ];
    // « En retard » disparaît quand il n'y en a plus.
    final status = _status == _Status.late && late.isEmpty
        ? _Status.all
        : _status;
    final visible = [
      for (final t in transactions ?? const <Transaction>[])
        if (!_removing.contains(t.id) && _matches(t, l10n, _filters)) t,
    ];
    // Nouvelles opérations de la même sélection : elles glissent dans la
    // liste (pas au premier affichage ni au changement de filtre).
    final selection = (_period, status, _filters, _search.text.trim());
    final known = _knownSelection == selection ? _known : null;
    final fresh = {
      if (known != null)
        for (final t in visible)
          if (!known.contains(t.id)) t.id,
    };
    if (!loading) {
      _known = {for (final t in visible) t.id};
      _knownSelection = selection;
    }

    /// Lignes affichées pour le statut choisi et [filters].
    int countFor(TransactionFilters filters) {
      final ops = (transactions ?? const <Transaction>[])
          .where((t) => _matches(t, l10n, filters))
          .length;
      final open = (dues ?? const <DueItem>[])
          .where((d) => _matchesDue(d, filters))
          .toList();
      final lateCount = open
          .where((d) => d.statusOn(now) == PlannedStatus.late)
          .length;
      return switch (status) {
        _Status.all => ops + open.length,
        _Status.paid => ops,
        _Status.planned => open.length,
        _Status.late => lateCount,
      };
    }

    final showPaid = status == _Status.all || status == _Status.paid;
    final showUpcoming = status == _Status.all || status == _Status.planned;
    final showLate = status != _Status.paid;
    final rows =
        (showPaid ? visible.length : 0) +
        (showUpcoming ? upcoming.length : 0) +
        (showLate ? late.length : 0);

    final paidSum = visible
        .where((t) => t.kind == TransactionKind.expense)
        .fold(Money.zero, (sum, t) => sum + t.amount);
    final incomeSum = visible
        .where((t) => t.kind == TransactionKind.income)
        .fold(Money.zero, (sum, t) => sum + t.amount);
    final plannedSum = periodDues.fold(Money.zero, (sum, d) => sum + d.amount);

    final categoryName = [
      for (final g in [...expenseGroups, ...incomeGroups]) g.category,
    ].where((c) => c.id == _filters.categoryId).firstOrNull?.name;
    final account = accounts
        .where((a) => a.id == _filters.accountId)
        .firstOrNull;
    final activeFilters = <(String, VoidCallback)>[
      if (_filters.kind case final kind?)
        (
          kind.label(l10n),
          () => setState(() => _filters = _filters.copyWith(kind: (null,))),
        ),
      if (categoryName != null)
        (
          categoryName,
          () =>
              setState(() => _filters = _filters.copyWith(categoryId: (null,))),
        ),
      if (account != null)
        (
          account.isArchived
              ? l10n.txArchivedAccount(account.name)
              : account.name,
          () =>
              setState(() => _filters = _filters.copyWith(accountId: (null,))),
        ),
    ];

    Widget dueHeader(String title, List<DueItem> items, Color ink) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: AppText.caption.semibold.copyWith(color: ink),
              ),
            ),
          ),
          Text(
            l10n.plannedGroupTotal(
              MoneyFormat.amount(
                items.fold(Money.zero, (sum, d) => sum + d.amount),
              ),
            ),
            style: AppText.caption.copyWith(color: colors.inkTertiary),
          ),
        ],
      ),
    );

    final query = _search.text.trim();
    final periodLabel = _periodLabel(relative);
    final isCustom = _period.span == PeriodSpan.custom;

    return AddOperationScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            12,
            AppSpacing.gutter,
            120,
          ),
          children: [
            header,
            if (_searchOpen) ...[
              TextField(
                controller: _search,
                autofocus: true,
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
            ],
            SegmentedChoice<PeriodSpan>(
              options: [
                (PeriodSpan.day, l10n.txSpanDay),
                (PeriodSpan.week, l10n.txSpanWeek),
                (PeriodSpan.month, l10n.txSpanMonth),
                (PeriodSpan.custom, l10n.txSpanCustom),
              ],
              selected: _period.span,
              onChanged: _setSpan,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  tooltip: l10n.txPrevPeriod,
                  onPressed: isCustom
                      ? null
                      : () => setState(() => _period = _period.shift(-1)),
                  icon: const Icon(AppIcons.caretLeftBold, size: 16),
                ),
                Expanded(
                  child: Semantics(
                    button: isCustom,
                    label: isCustom ? l10n.txChoosePeriod(periodLabel) : null,
                    excludeSemantics: isCustom,
                    child: InkWell(
                      onTap: isCustom ? _choosePeriod : null,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 6,
                          children: [
                            if (isCustom)
                              Icon(
                                AppIcons.calendarBlank,
                                size: 16,
                                color: colors.inkSecondary,
                              ),
                            Flexible(
                              child: Text(
                                periodLabel,
                                textAlign: TextAlign.center,
                                style: AppText.bodyLarge.semibold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.txNextPeriod,
                  onPressed: isCustom
                      ? null
                      : () => setState(() => _period = _period.shift(1)),
                  icon: const Icon(AppIcons.caretRightBold, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _Summary(
              loading: loading,
              paid: paidSum,
              planned: plannedSum,
              count: rows,
              note: incomeSum.value > 0
                  ? l10n.txSumNoteIncome(MoneyFormat.signed(incomeSum))
                  : l10n.txSumNotePlanned,
            ),
            const SizedBox(height: 14),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: 8,
                      children: [
                        for (final (value, label) in [
                          (_Status.all, l10n.txStatusAll),
                          (_Status.paid, l10n.txStatusPaid),
                          (_Status.planned, l10n.txStatusPlanned),
                          if (late.isNotEmpty)
                            (_Status.late, l10n.txStatusLate('${late.length}')),
                        ])
                          ChoicePill(
                            label: label,
                            height: 36,
                            selected: status == value,
                            onTap: () => setState(() => _status = value),
                          ),
                      ],
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: _filters.count == 0
                      ? l10n.txFilters
                      : l10n.txFiltersActive('${_filters.count}'),
                  excludeSemantics: true,
                  child: ChoicePill(
                    label: _filters.count == 0
                        ? l10n.txFilters
                        : '${l10n.txFilters} · ${_filters.count}',
                    icon: AppIcons.dotsThree,
                    height: 36,
                    selected: _filters.count > 0,
                    onTap: () async {
                      final picked = await showTransactionFilters(
                        context,
                        initial: _filters,
                        expenseCategories: [
                          for (final g in expenseGroups) g.category,
                        ],
                        incomeCategories: [
                          for (final g in incomeGroups) g.category,
                        ],
                        accounts: accounts,
                        countFor: countFor,
                      );
                      if (picked != null && mounted) {
                        setState(() => _filters = picked);
                      }
                    },
                  ),
                ),
              ],
            ),
            if (activeFilters.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (label, remove) in activeFilters)
                    InputChip(
                      label: Text(label),
                      onDeleted: remove,
                      deleteButtonTooltipMessage: l10n.txRemoveFilter(label),
                      deleteIcon: const Icon(AppIcons.xBold, size: 12),
                    ),
                ],
              ),
            ],
            // Changement de période, de statut ou de filtre : la liste
            // passe en fondu.
            AnimatedSwitcher(
              duration: Motion.of(context, Motion.base),
              switchInCurve: Motion.ease,
              switchOutCurve: Motion.easeIn,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              child: Column(
                key: ValueKey((selection, loading)),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (loading)
                    const _Skeleton()
                  else if (rows == 0)
                    _NoResult(
                      title: query.isEmpty
                          ? l10n.txNothingTitle
                          : l10n.txNoResultTitle,
                      body: query.isNotEmpty
                          ? l10n.txNoResultPeriod(query)
                          : status == _Status.planned
                          ? l10n.txNothingPlanned
                          : l10n.txNothingFilters,
                      onReset:
                          _filters.count > 0 ||
                              query.isNotEmpty ||
                              status != _Status.all
                          ? _resetAll
                          : null,
                    )
                  else ...[
                    if (showLate && late.isNotEmpty) ...[
                      dueHeader(l10n.plannedLateGroup, late, colors.warning),
                      for (final d in late)
                        DueRow(
                          due: d,
                          now: now,
                          meta: dueMeta(l10n, relative, d, now),
                        ),
                    ],
                    if (showUpcoming && upcoming.isNotEmpty) ...[
                      dueHeader(
                        l10n.plannedUpcomingGroup,
                        upcoming,
                        colors.inkTertiary,
                      ),
                      for (final d in upcoming)
                        DueRow(
                          due: d,
                          now: now,
                          meta: dueMeta(l10n, relative, d, now),
                        ),
                    ],
                    if (showPaid)
                      for (final (day, items) in groupByDay(visible)) ...[
                        DayHeader(relative.header(day)),
                        for (final t in items)
                          _SwipeToDelete(
                            key: ValueKey('tx-${t.id}'),
                            onDelete: () => _swipeDelete(t),
                            child: fresh.contains(t.id)
                                ? FadeSlideIn(
                                    child: TransactionTile(
                                      transaction: t,
                                      onTap: () => context.go(
                                        AppRoutes.transactionDetail(t.id),
                                      ),
                                    ),
                                  )
                                : TransactionTile(
                                    transaction: t,
                                    onTap: () => context.go(
                                      AppRoutes.transactionDetail(t.id),
                                    ),
                                  ),
                          ),
                      ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dépenses · Planifiées · Opérations, puis une phrase.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.loading,
    required this.paid,
    required this.planned,
    required this.count,
    required this.note,
  });

  final bool loading;
  final Money paid;
  final Money planned;
  final int count;
  final String note;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    // Les totaux comptent vers leur nouvelle valeur (360 ms).
    Widget cell(
      String label,
      int value,
      String Function(int value) format, {
      Color? color,
    }) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(
            label,
            style: AppText.caption.copyWith(color: colors.inkSecondary),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: loading
                ? const Text('…', style: AppText.sectionTitle)
                : CountingValue(
                    value: value,
                    firstDuration: Duration.zero,
                    builder: (context, v) => Text(
                      format(v),
                      style: AppText.sectionTitle.copyWith(color: color),
                    ),
                  ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Row(
          spacing: 12,
          children: [
            cell(
              l10n.txSumPaid,
              paid.value,
              (v) => MoneyFormat.amount(Money(v)),
              color: colors.expense,
            ),
            cell(
              l10n.txSumPlanned,
              planned.value,
              (v) => MoneyFormat.amount(Money(v)),
              color: colors.info,
            ),
            cell(l10n.txSumCount, count, (v) => '$v'),
          ],
        ),
        Text(note, style: AppText.caption.copyWith(color: colors.inkTertiary)),
      ],
    );
  }
}

/// Lignes grisées pendant le chargement.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  static const _widths = [0.62, 0.48, 0.70, 0.54, 0.66, 0.45];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: context.l10n.txLoading,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Column(
            spacing: 18,
            children: [
              for (final width in _widths)
                Row(
                  spacing: 12,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.chip,
                      ),
                    ),
                    Expanded(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: width,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors.chip,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final today = CalendarDate.of(now);
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
            style: AppText.headline,
          ),
          Text(
            l10n.txEmptyBody,
            textAlign: TextAlign.center,
            style: AppText.bodyLarge.prose.copyWith(color: colors.inkSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => openNewOperation(context),
              icon: const Icon(AppIcons.plusBold, size: 18),
              label: Text(l10n.txEmptyAction),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(
                AppRoutes.newTransaction(
                  kind: TransactionKind.expense,
                  plannedDue: DateTime(today.year, today.month, today.day + 1),
                ),
              ),
              icon: const Icon(AppIcons.calendarBlank, size: 18),
              label: Text(l10n.txEmptyPlan),
            ),
          ),
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.quickEntry()),
            icon: const Icon(AppIcons.microphoneBold, size: 18),
            label: Text(l10n.txEmptyDictate),
          ),
        ],
      ),
    );
  }
}

class _NoResult extends StatelessWidget {
  const _NoResult({required this.title, required this.body, this.onReset});

  final String title;
  final String body;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
          Text(title, style: AppText.sectionTitle),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppText.body.prose.copyWith(color: colors.inkSecondary),
          ),
          if (onReset != null)
            OutlinedButton(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              child: Text(context.l10n.txShowAll),
            ),
        ],
      ),
    );
  }
}

/// Glisser une opération vers la gauche pour la supprimer (léger retour
/// haptique au seuil) ; action « Supprimer » pour les lecteurs d'écran.
class _SwipeToDelete extends StatelessWidget {
  const _SwipeToDelete({
    required this.child,
    required this.onDelete,
    super.key,
  });

  final Widget child;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Semantics(
      hint: l10n.txSwipeHint,
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.txDelete): onDelete,
      },
      child: Dismissible(
        key: key!,
        direction: DismissDirection.endToStart,
        dismissThresholds: const {DismissDirection.endToStart: 0.4},
        movementDuration: Motion.of(context, Motion.base),
        resizeDuration: Motion.of(context, Motion.slow),
        onUpdate: (details) {
          if (details.reached && !details.previousReached) {
            unawaited(Haptics.light());
          }
        },
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: colors.negativeSoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(AppIcons.trash, color: colors.negative, size: 20),
        ),
        child: child,
      ),
    );
  }
}
