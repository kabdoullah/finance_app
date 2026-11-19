import 'dart:async';

import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../core/clock.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/formatting/text_search.dart';
import '../../../core/money/money.dart';
import '../../../core/time/month.dart';
import '../../../l10n/l10n.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/accounts_summary.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../budgets/domain/budget.dart';
import '../../budgets/presentation/budgets_providers.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_providers.dart';
import '../../forecast/domain/forecast.dart';
import '../../forecast/domain/purchase_simulation.dart';
import '../../forecast/presentation/forecast_providers.dart';
import '../../goals/data/goals_repository.dart';
import '../../goals/domain/savings_goal.dart';
import '../../goals/presentation/goals_providers.dart';
import '../../quick_entry/domain/quick_entry_parser.dart';
import '../../recurring/domain/recurring_operation.dart';
import '../../recurring/presentation/recurring_providers.dart';
import '../../transactions/domain/expense_breakdown.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../domain/assistant_reply.dart';

/// Outils proposés à Gemma : il choisit l'outil et ses paramètres, puis
/// l'application calcule avec ses propres moteurs (les mêmes que les
/// écrans). Gemma ne calcule jamais rien.
class AssistantToolbox {
  AssistantToolbox(this._ref, this._l10n);

  final Ref _ref;
  final AppLocalizations _l10n;
  static const _locale = 'fr';

  /// Codes stables → catégories de dépenses et comptes (voir [prepare]).
  final _categories = <String, Category>{};
  final _accounts = <String, Account>{};

  /// Question en cours : une opération préparée est lue dans la phrase de
  /// l'utilisateur, jamais dans la reformulation de Gemma.
  String question = '';

  static const instruction =
      "Tu es le Copilote d'une application de finances personnelles en Côte "
      "d'Ivoire (montants en FCFA). Tu ne calcules jamais toi-même : pour "
      'toute question sur les dépenses, les budgets, les soldes, une '
      "prévision ou un achat, appelle l'outil adapté, puis explique son "
      'résultat en une ou deux phrases, en français, en reprenant '
      "exactement ses montants. N'invente aucun chiffre. Tutoie toujours "
      "l'utilisateur (« tu », « ton », « tes », jamais « vous »). Sans "
      'période précisée, prends le mois en cours, sans la demander. Pour une '
      'autre question, réponds brièvement sans aucun chiffre ; pas de '
      'conseil de placement.';

  /// Construit les outils à partir des catégories et comptes actuels.
  Future<List<Tool>> prepare() async {
    _categories.clear();
    _accounts.clear();
    final groups = await _read(categoryGroupsProvider(CategoryKind.expense));
    final hints = <String>[];
    for (final group in groups) {
      if (group.category.isHidden) continue;
      final code = stableCode(group.category.name, _categories.keys);
      _categories[code] = group.category;
      final children = [for (final c in group.visibleChildren) c.name];
      if (children.isNotEmpty) hints.add('$code : ${children.join(', ')}');
    }
    for (final account in await _read(activeAccountsProvider)) {
      _accounts[stableCode(account.name, _accounts.keys)] = account;
    }
    final category = {
      'type': 'string',
      'enum': _categories.keys.toList(),
      'description': hints.join('. '),
    };
    return [
      Tool(
        name: 'get_spending',
        description:
            'Total des dépenses sur une période, éventuellement pour une '
            'catégorie, avec les catégories qui coûtent le plus.',
        parameters: {
          'type': 'object',
          'properties': {
            'period': {
              'type': 'string',
              'enum': ['today', 'this_week', 'this_month', 'last_month'],
              'description': "this_month si la période n'est pas précisée.",
            },
            'category': category,
          },
        },
      ),
      Tool(
        name: 'get_budget_status',
        description:
            'Budgets du mois : reste, et combien dépenser par jour et sur '
            '7 jours. Sans catégorie : tous les budgets.',
        parameters: {
          'type': 'object',
          'properties': {'category': category},
        },
      ),
      Tool(
        name: 'get_balance',
        description: "Solde d'un compte, ou de tous les comptes.",
        parameters: {
          'type': 'object',
          'properties': {
            'account': {'type': 'string', 'enum': _accounts.keys.toList()},
          },
        },
      ),
      const Tool(
        name: 'get_forecast',
        description: 'Solde prévu dans 7, 30 ou 90 jours (fin du mois : 30).',
        parameters: {
          'type': 'object',
          'properties': {
            'days': {
              'type': 'integer',
              'enum': [7, 30, 90],
            },
          },
          'required': ['days'],
        },
      ),
      const Tool(
        name: 'simulate_purchase',
        description:
            'Dit si un achat est possible sans mettre le disponible à '
            'découvert dans les 30 jours. Prix en FCFA.',
        parameters: {
          'type': 'object',
          'properties': {
            'label': {'type': 'string'},
            'price': {'type': 'integer'},
          },
          'required': ['price'],
        },
      ),
      const Tool(
        name: 'prepare_operation',
        description:
            'Prépare une dépense, un revenu ou un transfert que '
            "l'utilisateur décrit (« Taxi 2 500 ce matin avec Wave »). "
            "L'utilisateur confirme avant tout enregistrement.",
        parameters: {
          'type': 'object',
          'properties': {
            'text': {'type': 'string'},
          },
        },
      ),
      const Tool(
        name: 'get_savings_overview',
        description:
            "Bilan d'épargne : revenus et dépenses moyens par mois, part "
            "des charges fixes. Pour « pourquoi j'ai du mal à économiser ».",
        parameters: {'type': 'object', 'properties': <String, Object?>{}},
      ),
      const Tool(
        name: 'plan_savings_goal',
        description:
            'Combien mettre de côté par mois pour réunir une somme en un '
            'nombre de mois, comparé à l\'épargne moyenne.',
        parameters: {
          'type': 'object',
          'properties': {
            'amount': {'type': 'integer'},
            'months': {'type': 'integer'},
            'label': {'type': 'string'},
          },
          'required': ['amount', 'months'],
        },
      ),
    ];
  }

  Future<ToolOutcome> run(String name, Map<String, dynamic> args) =>
      switch (name) {
        'get_spending' => _spending(args),
        'get_budget_status' => _budgets(args),
        'get_balance' => _balance(args),
        'get_forecast' => _forecast(args),
        'simulate_purchase' => _simulate(args),
        'prepare_operation' => _prepare(),
        'get_savings_overview' => _savings(),
        'plan_savings_goal' => _goal(args),
        _ => Future.value(
          ToolOutcome(data: {'error': 'unknown tool'}, summary: _l10n.asError),
        ),
      };

  DateTime get _now => _ref.read(clockProvider)();

  /// Première valeur d'un fournisseur asynchrone, en l'écoutant le temps de
  /// la lecture (non écouté, il serait libéré avant d'avoir répondu).
  Future<T> _read<T>(ProviderListenable<AsyncValue<T>> provider) {
    final completer = Completer<T>();
    void settle(AsyncValue<T> value) {
      if (completer.isCompleted) return;
      switch (value) {
        case AsyncData(:final value):
          completer.complete(value);
        case AsyncError(:final error, :final stackTrace):
          completer.completeError(error, stackTrace);
        default:
          break;
      }
    }

    final subscription = _ref.listen(provider, (_, next) => settle(next));
    settle(subscription.read());
    return completer.future.whenComplete(subscription.close);
  }

  String _fcfa(Money m) => '${MoneyFormat.amount(m)} ${_l10n.currencyLabel}';
  String _amount(Money m) => MoneyFormat.amount(m);
  String _date(DateTime d) => AppDateFormat.dayMonth(d, _locale);

  // ---------------------------------------------------------------------------
  // Dépenses.

  Future<ToolOutcome> _spending(Map<String, dynamic> args) async {
    final now = _now;
    final today = DateTime(now.year, now.month, now.day);
    final (start, end, label) = switch (args['period']) {
      'today' => (today, now, _l10n.asPeriodToday),
      'this_week' => (
        today.subtract(Duration(days: today.weekday - 1)),
        now,
        _l10n.asPeriodWeek,
      ),
      'last_month' => (
        Month.of(now).previous.start,
        Month.of(now).start,
        _l10n.asPeriodLastMonth,
      ),
      _ => (Month.of(now).start, now, _l10n.asPeriodMonth),
    };
    final months = {Month.of(start), Month.of(end), Month.of(now)};
    final transactions = <Transaction>[
      for (final month in months)
        ...await _read(monthTransactionsProvider(month)),
    ];
    final category = _categories[args['category']];
    final expenses = [
      for (final t in transactions)
        if (t.kind == TransactionKind.expense &&
            !t.occurredAt.isBefore(start) &&
            t.occurredAt.isBefore(end.add(const Duration(seconds: 1))) &&
            (category == null || t.mainCategory?.id == category.id))
          t,
    ];
    final total = Money(expenses.fold(0, (sum, t) => sum + t.amount.value));
    const link = ReplyLink(ReplyLinkTarget.transactions);
    if (expenses.isEmpty) {
      return ToolOutcome(
        data: {'period': label, 'total_fcfa': 0},
        summary: _l10n.asSpendingNone(label),
        link: link,
      );
    }

    final List<ReplyRow> rows;
    final List<Map<String, Object?>> parts;
    if (category == null) {
      final breakdown = ExpenseBreakdown.of(expenses);
      final max = breakdown.shares.first.amount.value;
      rows = [
        for (final share in breakdown.shares)
          ReplyRow(
            share.category?.name ?? _l10n.accountsOthers,
            _fcfa(share.amount),
            ratio: share.amount.value / max,
          ),
      ];
      parts = [
        for (final share in breakdown.shares)
          {
            'category': share.category?.name ?? _l10n.accountsOthers,
            'amount_fcfa': share.amount.value,
            'percent': share.percent,
          },
      ];
    } else {
      // Détail par sous-catégorie.
      final bySub = <String, int>{};
      for (final t in expenses) {
        final name = t.category?.name ?? category.name;
        bySub[name] = (bySub[name] ?? 0) + t.amount.value;
      }
      final sorted = bySub.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      rows = [
        for (final e in sorted)
          ReplyRow(
            e.key,
            _fcfa(Money(e.value)),
            ratio: e.value / sorted.first.value,
          ),
      ];
      parts = [
        for (final e in sorted) {'name': e.key, 'amount_fcfa': e.value},
      ];
    }

    final top = parts.first;
    final summary = category == null
        ? [
            _l10n.asSpending(_amount(total), label),
            if (top['category'] != _l10n.accountsOthers)
              _l10n.asSpendingTop(
                '${top['category']}',
                _amount(Money(top['amount_fcfa']! as int)),
                '${top['percent']}',
              ),
          ].join(' ')
        : _l10n.asSpendingCategory(_amount(total), category.name, label);
    return ToolOutcome(
      data: {
        'period': label,
        'category': ?category?.name,
        'total_fcfa': total.value,
        'details': parts,
      },
      summary: summary,
      rows: rows,
      link: link,
    );
  }

  // ---------------------------------------------------------------------------
  // Budgets.

  Future<ToolOutcome> _budgets(Map<String, dynamic> args) async {
    final now = _now;
    final month = Month.of(now);
    final groups = await _read(categoryGroupsProvider(CategoryKind.expense));
    final overview = BudgetsOverview.of(
      budgets: await _read(budgetsProvider),
      monthTransactions: await _read(monthTransactionsProvider(month)),
      expenseCategories: [
        for (final g in groups)
          if (!g.category.isHidden) g.category,
      ],
      now: now,
    );
    const link = ReplyLink(ReplyLinkTarget.budgets);
    final daysLeft = month.end
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    final monthName = RelativeDate(_l10n, _locale, now).month(month);

    final category = _categories[args['category']];
    if (category != null) {
      final status = overview.categories
          .where((s) => s.budget.category?.id == category.id)
          .firstOrNull;
      if (status == null) {
        return ToolOutcome(
          data: {'category': category.name, 'budget': 'none'},
          summary: _l10n.asNoBudgetCategory(category.name),
          link: link,
        );
      }
      return ToolOutcome(
        data: {
          'category': category.name,
          'limit_fcfa': status.budget.limit.value,
          'spent_fcfa': status.spent.value,
          'remaining_fcfa': status.remaining.value,
          'percent': status.percent,
          'days_left': daysLeft,
          'per_day_fcfa': dailyAllowance(status.remaining, daysLeft).value,
        },
        summary: status.remaining.value < 0
            ? _l10n.asBudgetCategoryExceeded(
                category.name,
                _amount(-status.remaining),
              )
            : _l10n.asBudgetCategory(
                category.name,
                _amount(status.remaining),
                _amount(status.budget.limit),
              ),
        rows: [
          ReplyRow(
            category.name,
            _l10n.asRowSpentOf(
              _amount(status.spent),
              _amount(status.budget.limit),
            ),
            ratio: (status.spent.value / status.budget.limit.value)
                .clamp(0, 1)
                .toDouble(),
          ),
          ReplyRow(_l10n.asRowRemaining(monthName), _fcfa(status.remaining)),
          ReplyRow(_l10n.asRowDaysLeft, '$daysLeft'),
        ],
        link: link,
      );
    }

    final statuses = [?overview.global, ...overview.categories];
    if (statuses.isEmpty) {
      return ToolOutcome(
        data: const {'budgets': 'none'},
        summary: _l10n.asNoBudget,
        link: link,
      );
    }
    // Budget global s'il existe, sinon somme des budgets par catégorie.
    final remaining =
        overview.global?.remaining ??
        Money(overview.categories.fold(0, (s, b) => s + b.remaining.value));
    final perDay = dailyAllowance(remaining, daysLeft);
    final week = Money(perDay.value * (daysLeft < 7 ? daysLeft : 7));
    return ToolOutcome(
      data: {
        'remaining_fcfa': remaining.value,
        'days_left': daysLeft,
        'per_day_fcfa': perDay.value,
        'next_7_days_fcfa': week.value,
        'budgets': [
          for (final s in statuses)
            {
              'category': s.budget.category?.name ?? 'global',
              'limit_fcfa': s.budget.limit.value,
              'spent_fcfa': s.spent.value,
              'remaining_fcfa': s.remaining.value,
              'percent': s.percent,
            },
        ],
      },
      summary: remaining.value < 0
          ? _l10n.asBudgetExceeded(_amount(-remaining))
          : _l10n.asBudget(_amount(week), _amount(perDay)),
      rows: [
        ReplyRow(_l10n.asRowRemaining(monthName), _fcfa(remaining)),
        ReplyRow(_l10n.asRowDaysLeft, '$daysLeft'),
        ReplyRow(_l10n.asRowWeek, _fcfa(week)),
      ],
      link: link,
    );
  }

  // ---------------------------------------------------------------------------
  // Soldes.

  Future<ToolOutcome> _balance(Map<String, dynamic> args) async {
    final accounts = await _read(activeAccountsProvider);
    const link = ReplyLink(ReplyLinkTarget.accounts);
    final account = _accounts[args['account']];
    if (account != null) {
      final current = accounts.where((a) => a.id == account.id).firstOrNull;
      final balance = current?.balance ?? account.balance;
      return ToolOutcome(
        data: {'account': account.name, 'balance_fcfa': balance.value},
        summary: _l10n.asBalanceAccount(_amount(balance), account.name),
        rows: [ReplyRow(account.name, _fcfa(balance))],
        link: link,
      );
    }
    final summary = AccountsSummary.of(accounts);
    return ToolOutcome(
      data: {
        'total_fcfa': summary.total.value,
        'accounts': [
          for (final a in accounts)
            {'account': a.name, 'balance_fcfa': a.balance.value},
        ],
      },
      summary: _l10n.asBalance(_amount(summary.total)),
      rows: [
        for (final a in accounts) ReplyRow(a.name, _fcfa(a.balance)),
        ReplyRow(_l10n.asRowTotal, _fcfa(summary.total)),
      ],
      link: link,
    );
  }

  // ---------------------------------------------------------------------------
  // Prévision et simulation.

  /// Prévision du même calcul que l'onglet Prévisions, ou `null` si
  /// l'historique est trop court.
  Future<Forecast?> _computeForecast(ForecastHorizon horizon) async {
    final now = _now;
    final history = await _read(spendingHistoryProvider);
    if (history.daysOfHistory(now) < Forecast.minHistoryDays) return null;
    final accounts = await _read(activeAccountsProvider);
    return Forecast.compute(
      now: now,
      horizon: horizon,
      balance: AccountsSummary.of(accounts).total,
      history: history,
      recurring: await _read(recurringOperationsProvider),
    );
  }

  static ForecastHorizon _horizon(int days) => ForecastHorizon.values
      .firstWhere((h) => h.days == days, orElse: () => ForecastHorizon.month);

  ToolOutcome get _tooEarly => ToolOutcome(
    data: const {'forecast': 'not_enough_history'},
    summary: _l10n.asForecastTooEarly,
    link: const ReplyLink(ReplyLinkTarget.forecast),
  );

  Future<ToolOutcome> _forecast(Map<String, dynamic> args) async {
    final days = args['days'];
    final forecast = await _computeForecast(
      _horizon(days is num ? days.round() : 30),
    );
    if (forecast == null) return _tooEarly;
    final level = switch (forecast.reliability) {
      ForecastReliability.high => _l10n.forecastReliabilityHigh,
      ForecastReliability.medium => _l10n.forecastReliabilityMedium,
      ForecastReliability.low => _l10n.forecastReliabilityLow,
    };
    final (low, high) = forecast.endRange;
    final end = _date(forecast.endDate);
    final negative = forecast.negativeOn;
    return ToolOutcome(
      data: {
        'date': end,
        'expected_balance_fcfa': forecast.endBalance.value,
        'low_fcfa': low.value,
        'high_fcfa': high.value,
        'reliability': level,
        'below_zero_on': ?(negative == null ? null : _date(negative)),
      },
      summary: [
        _l10n.asForecast(_amount(forecast.endBalance), end, level),
        if (negative != null) _l10n.asForecastNegative(_date(negative)),
      ].map(AppDateFormat.sentence).join(' '),
      rows: [
        ReplyRow(_l10n.asRowForecastOn(end), '≈ ${_fcfa(forecast.endBalance)}'),
        ReplyRow(
          _l10n.asRowRange,
          _l10n.asRowRangeValue(_amount(low), _amount(high)),
        ),
        ReplyRow(_l10n.asRowReliability, level),
      ],
      link: const ReplyLink(ReplyLinkTarget.forecast),
    );
  }

  Future<ToolOutcome> _simulate(Map<String, dynamic> args) async {
    final price = switch (args['price']) {
      final num p => p.round(),
      _ => 0,
    };
    final label = (args['label'] as String?)?.trim() ?? '';
    final link = ReplyLink(
      ReplyLinkTarget.simulation,
      simulationLabel: label.isEmpty ? null : label,
      simulationPrice: price > 0 ? price : null,
    );
    final forecast = await _computeForecast(_horizon(30));
    if (forecast == null || price <= 0) {
      return ToolOutcome(
        data: _tooEarly.data,
        summary: _tooEarly.summary,
        link: link,
      );
    }
    final reserved = await _read(reservedByAccountProvider);
    final simulation = PurchaseSimulation.compute(
      forecast: forecast,
      reserved: Money(reserved.values.fold(0, (s, m) => s + m.value)),
      price: Money(price),
      purchaseDay: 0,
    );
    final lowestDate = _date(simulation.lowestDate);
    final negative = simulation.negativeOn;
    final end = _date(simulation.endDate);
    final summary = switch (simulation.verdict) {
      PurchaseVerdict.possible => _l10n.asSimPossible(
        _amount(simulation.lowest),
        lowestDate,
      ),
      PurchaseVerdict.tight => _l10n.asSimTight(
        _amount(simulation.lowest),
        lowestDate,
      ),
      PurchaseVerdict.discouraged => _l10n.asSimDiscouraged(
        _date(negative ?? simulation.lowestDate),
      ),
    };
    return ToolOutcome(
      data: {
        'price_fcfa': price,
        'verdict': simulation.verdict.name,
        'lowest_available_fcfa': simulation.lowest.value,
        'lowest_on': lowestDate,
        'below_zero_on': ?(negative == null ? null : _date(negative)),
        'end_date': end,
        'end_with_purchase_fcfa': simulation.endBalance.value,
        'end_without_purchase_fcfa': simulation.endWithout.value,
      },
      summary: AppDateFormat.sentence(summary),
      rows: [
        ReplyRow(_l10n.asRowLowest, '≈ ${_fcfa(simulation.lowest)}'),
        ReplyRow(_l10n.asRowEndWith(end), '≈ ${_fcfa(simulation.endBalance)}'),
        ReplyRow(
          _l10n.asRowEndWithout(end),
          '≈ ${_fcfa(simulation.endWithout)}',
        ),
      ],
      link: link,
    );
  }

  // ---------------------------------------------------------------------------
  // Opération préparée, bilan d'épargne, objectif.

  Future<ToolOutcome> _prepare() async {
    final accounts = await _read(activeAccountsProvider);
    final lastUsed = await _ref
        .read(transactionsRepositoryProvider)
        .lastUsedAccountId();
    final operations = const QuickEntryParser().parse(
      question,
      QuickEntryContext(
        now: _now,
        accounts: accounts,
        expenseGroups: await _read(
          categoryGroupsProvider(CategoryKind.expense),
        ),
        incomeGroups: await _read(categoryGroupsProvider(CategoryKind.income)),
        defaultAccountId: lastUsed ?? accounts.firstOrNull?.id,
      ),
    );
    final usable = [
      for (final op in operations)
        if (op.amount != null) op,
    ];
    if (usable.isEmpty) {
      return ToolOutcome(
        data: const {'prepared': 0},
        summary: _l10n.asPreparedNone,
      );
    }
    return ToolOutcome(
      data: {
        'prepared': usable.length,
        'saved': false,
        'operations': [
          for (final op in usable)
            {'kind': op.kind.name, 'amount_fcfa': op.amount!.value},
        ],
      },
      summary: usable.length == 1
          ? _l10n.asPrepared
          : _l10n.asPreparedMany(usable.length),
      prepared: usable,
    );
  }

  Future<ToolOutcome> _savings() async {
    const link = ReplyLink(ReplyLinkTarget.budgets);
    final history = await _read(spendingHistoryProvider);
    final goals = _ref.read(goalsRepositoryProvider);
    final surplus = await goals.averageMonthlySurplus();
    final expenses = await goals.averageMonthlyExpenses();
    if (history.daysOfHistory(_now) < GoalsRepository.minHistoryDays ||
        surplus == null ||
        expenses == null ||
        expenses.value <= 0) {
      return ToolOutcome(
        data: const {'savings': 'not_enough_history'},
        summary: _l10n.asSavingsTooEarly,
        link: link,
      );
    }
    final income = surplus + expenses;
    final fixed = RecurringTotals.of(await _read(recurringOperationsProvider))
        .expense;
    final percent = (fixed.value * 100 / expenses.value).round();
    final top = income.value > expenses.value ? income.value : expenses.value;
    return ToolOutcome(
      data: {
        'average_income_fcfa': income.value,
        'average_expenses_fcfa': expenses.value,
        'average_savings_fcfa': surplus.value,
        'fixed_charges_fcfa': fixed.value,
        'fixed_percent': percent,
      },
      summary: surplus.value < 0
          ? _l10n.asSavingsDeficit(
              _amount(expenses),
              _amount(income),
              '$percent',
            )
          : _l10n.asSavings(_amount(income), _amount(expenses), '$percent'),
      rows: [
        ReplyRow(
          _l10n.asRowIncome,
          _fcfa(income),
          ratio: top == 0 ? 0 : income.value / top,
        ),
        ReplyRow(
          _l10n.asRowExpenses,
          _fcfa(expenses),
          ratio: top == 0 ? 0 : expenses.value / top,
        ),
        ReplyRow(
          '${_l10n.asRowFixed} ($percent %)',
          _fcfa(fixed),
          ratio: top == 0 ? 0 : (fixed.value / top).clamp(0, 1).toDouble(),
        ),
      ],
      link: link,
    );
  }

  Future<ToolOutcome> _goal(Map<String, dynamic> args) async {
    final amount = switch (args['amount']) {
      final num a => a.round(),
      _ => 0,
    };
    final months = switch (args['months']) {
      final num m => m.round().clamp(1, 120),
      _ => 0,
    };
    final label = (args['label'] as String?)?.trim() ?? '';
    if (amount <= 0 || months <= 0) {
      return ToolOutcome(
        data: const {'goal': 'invalid'},
        summary: _l10n.asFallback,
      );
    }
    final monthly = roundUpToHundred(Money((amount / months).ceil()));
    final now = _now;
    final deadline = DateTime(now.year, now.month + months, now.day);
    final surplus = await _ref
        .read(goalsRepositoryProvider)
        .averageMonthlySurplus();
    final link = ReplyLink(
      ReplyLinkTarget.goal,
      goalName: label.isEmpty ? null : label,
      goalTarget: amount,
      goalMonths: months,
    );
    return ToolOutcome(
      data: {
        'amount_fcfa': amount,
        'months': months,
        'monthly_fcfa': monthly.value,
        'deadline': AppDateFormat.dayMonthYear(deadline, _locale),
        'average_savings_fcfa': ?surplus?.value,
      },
      summary: surplus == null
          ? _l10n.asGoalUnknown(_amount(monthly))
          : surplus.value >= monthly.value
          ? _l10n.asGoalFeasible(_amount(monthly), _amount(surplus))
          : _l10n.asGoalHard(_amount(monthly), _amount(surplus)),
      rows: [
        ReplyRow(_l10n.asRowMonthly, _fcfa(monthly)),
        if (surplus != null) ReplyRow(_l10n.asRowSurplus, _fcfa(surplus)),
        ReplyRow(
          _l10n.asRowDeadline,
          AppDateFormat.dayMonthYear(deadline, _locale),
        ),
      ],
      link: link,
    );
  }
}
