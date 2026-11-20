import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/motion.dart';
import '../../../core/clock.dart';
import '../../../core/errors/result.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/segmented_choice.dart';
import '../../../l10n/l10n.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/account_picker_sheet.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../budgets/presentation/budget_widgets.dart';
import '../../categories/presentation/categories_providers.dart';
import '../../categories/presentation/category_icons.dart';
import '../../planned/domain/planned_draft.dart';
import '../../planned/domain/planned_expense.dart';
import '../../planned/presentation/planned_providers.dart';
import '../../settings/presentation/settings_providers.dart';
import '../domain/transaction.dart';
import '../domain/transaction_draft.dart';
import 'transaction_labels.dart';
import 'transactions_providers.dart';

/// Ajout d'une opération en 3 étapes (maquette Ajout-Transaction) :
/// 1. type et montant, 2. détails (dépense payée ou planifiée),
/// 3. confirmation. Sert aussi à modifier une dépense planifiée
/// ([editPlanned] : ouverture sur les détails, retour après
/// l'enregistrement).
class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({
    required this.initialKind,
    this.initialAccountId,
    this.editPlanned,
    this.initialPlannedDue,
    super.key,
  });

  final TransactionKind initialKind;
  final String? initialAccountId;
  final PlannedExpense? editPlanned;

  /// Ouvre en dépense « Planifiée » à cette date (depuis le calendrier).
  final DateTime? initialPlannedDue;

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  static const _maxDigits = 9;

  final _description = TextEditingController();
  final _name = TextEditingController();

  int _step = 1;
  late TransactionKind _kind = widget.initialKind;
  String _digits = '';
  String? _categoryId;
  String? _accountId;
  String? _toAccountId;
  late DateTime _date;
  bool _descriptionOpen = false;
  bool _saving = false;

  /// Dépense « Planifiée » (à payer plus tard) plutôt que « Payée ».
  bool _planned = false;
  late DateTime _due;

  /// « Planifier » touché sans libellé : le champ passe en erreur.
  bool _nameTried = false;

  /// Étape 3 : opération enregistrée et nouveau solde du compte concerné.
  Transaction? _saved;
  Account? _savedAccount;

  /// Étape 3 d'une dépense planifiée.
  PlannedExpense? _savedPlanned;

  bool get _isPlanned => _kind == TransactionKind.expense && _planned;

  Money get _amount => _digits.isEmpty ? Money.zero : Money(int.parse(_digits));

  @override
  void initState() {
    super.initState();
    _date = ref.read(clockProvider)();
    _due = _tomorrow();
    if (widget.initialPlannedDue case final due?
        when due.isAfter(CalendarDate.of(_date))) {
      _planned = true;
      _due = CalendarDate.of(due);
    }
    _accountId = widget.initialAccountId;
    if (widget.editPlanned case final p?) {
      _planned = true;
      _step = 2;
      _digits = '${p.amount.value}';
      _name.text = p.name;
      _categoryId = p.category.id;
      _accountId = p.accountId;
      _due = p.dueDate;
      _description.text = p.note ?? '';
      _descriptionOpen = p.note != null;
    }
    if (_accountId == null) {
      // Par défaut : le compte de la dernière opération saisie.
      ref.read(transactionsRepositoryProvider).lastUsedAccountId().then((id) {
        if (mounted && _accountId == null && id != null) {
          setState(() => _accountId = id);
        }
      });
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _name.dispose();
    super.dispose();
  }

  DateTime _tomorrow() {
    final today = CalendarDate.of(ref.read(clockProvider)());
    return DateTime(today.year, today.month, today.day + 1);
  }

  void _press(String key) => setState(() {
    if (key == 'del') {
      if (_digits.isNotEmpty) {
        _digits = _digits.substring(0, _digits.length - 1);
      }
      return;
    }
    if (_digits.isEmpty && (key == '0' || key == '000')) return;
    if (_digits.length + key.length > _maxDigits) return;
    _digits += key;
  });

  void _setKind(TransactionKind kind) => setState(() {
    _kind = kind;
    _categoryId = null;
  });

  /// Compte choisi s'il est toujours actif, sinon le premier compte actif.
  String? _from(List<Account> accounts) {
    if (accounts.isEmpty) return null;
    return accounts.any((a) => a.id == _accountId)
        ? _accountId
        : accounts.first.id;
  }

  String? _to(List<Account> accounts, String? from) {
    final others = accounts.where((a) => a.id != from).toList();
    if (others.isEmpty) return null;
    return others.any((a) => a.id == _toAccountId)
        ? _toAccountId
        : others.first.id;
  }

  Future<void> _save(List<Account> accounts) async {
    if (_isPlanned) return _savePlanned(accounts);
    final from = _from(accounts);
    final to = _to(accounts, from);
    final draft = TransactionDraft(
      kind: _kind,
      amount: _amount,
      occurredAt: _date,
      accountId: from,
      toAccountId: _kind == TransactionKind.transfer ? to : null,
      categoryId: _kind == TransactionKind.transfer ? null : _categoryId,
      description: _description.text,
    );

    setState(() => _saving = true);
    final result = await ref.read(transactionsRepositoryProvider).create(draft);
    if (!mounted) return;

    switch (result) {
      case Ok(:final value):
        unawaited(Haptics.success());
        final balanceAccountId = value.toAccountId ?? value.accountId;
        final account = await ref
            .read(accountsRepositoryProvider)
            .watchById(balanceAccountId)
            .first;
        if (!mounted) return;
        setState(() {
          _saving = false;
          _saved = value;
          _savedAccount = account;
          _step = 3;
        });
      case Err(failure: ValidationFailure<TransactionFieldError>(:final errors))
          when errors.contains(TransactionFieldError.accountUnavailable):
        setState(() => _saving = false);
        _showMessage(context.l10n.txAccountUnavailable);
      case Err():
        setState(() => _saving = false);
        _showMessage(context.l10n.errorGeneric);
    }
  }

  Future<void> _savePlanned(List<Account> accounts) async {
    if (_name.text.trim().isEmpty) {
      setState(() => _nameTried = true);
      return;
    }
    final draft = PlannedDraft(
      name: _name.text,
      amount: _amount,
      dueDate: _due,
      categoryId: _categoryId,
      accountId: _from(accounts),
      note: _description.text,
    );
    final repository = ref.read(plannedRepositoryProvider);
    final editing = widget.editPlanned;
    setState(() => _saving = true);
    final result = editing == null
        ? await repository.create(draft)
        : await repository.update(editing.id, draft);
    if (!mounted) return;
    final l10n = context.l10n;
    switch (result) {
      case Ok(:final value):
        unawaited(Haptics.success());
        if (editing != null) {
          _showMessage(l10n.plannedUpdated);
          context.pop();
          return;
        }
        setState(() {
          _saving = false;
          _savedPlanned = value;
          _step = 3;
        });
      case Err(failure: ValidationFailure<PlannedFieldError>(:final errors)):
        setState(() => _saving = false);
        _showMessage(
          errors.contains(PlannedFieldError.accountUnavailable)
              ? l10n.txAccountUnavailable
              : errors.contains(PlannedFieldError.dueNotInFuture)
              ? l10n.plannedDueMissingFuture
              : l10n.errorGeneric,
        );
      case Err():
        setState(() => _saving = false);
        _showMessage(l10n.errorGeneric);
    }
  }

  void _reset() => setState(() {
    _step = 1;
    _digits = '';
    _categoryId = null;
    _description.clear();
    _descriptionOpen = false;
    _saved = null;
    _savedPlanned = null;
    _name.clear();
    _nameTried = false;
    _due = _tomorrow();
    _date = ref.read(clockProvider)();
  });

  Future<void> _pickDue() async {
    final tomorrow = _tomorrow();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due.isBefore(tomorrow) ? tomorrow : _due,
      firstDate: tomorrow,
      lastDate: DateTime(tomorrow.year + 5, 12, 31),
      helpText: context.l10n.plannedDuePickerHelp,
    );
    if (picked == null || !mounted) return;
    setState(() => _due = CalendarDate.of(picked));
  }

  Future<void> _pickDate() async {
    final now = ref.read(clockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.toLocal(),
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    // On garde l'heure de saisie : utile pour ordonner les opérations du jour.
    setState(
      () => _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        now.hour,
        now.minute,
      ),
    );
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accounts = ref.watch(activeAccountsProvider).value;

    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text(
          widget.editPlanned != null
              ? l10n.plannedEditTitle
              : _step == 3
              ? (_savedPlanned != null
                    ? l10n.plannedSavedHeading
                    : l10n.txSavedTitle)
              : l10n.txNewTitle,
        ),
      ),
      body: SafeArea(
        child: switch (accounts) {
          null => const SizedBox.shrink(),
          [] => _NeedAccount(message: l10n.txNeedAccount),
          _ => switch (_step) {
            1 => _amountStep(context),
            2 => _detailsStep(context, accounts),
            _ when _savedPlanned != null => _plannedSavedStep(context),
            _ => _savedStep(context),
          },
        },
      ),
    );
  }

  Widget _amountStep(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final hasAmount = _amount.value > 0;
    return Column(
      children: [
        if (widget.editPlanned == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: SegmentedChoice(
              options: [
                for (final kind in TransactionKind.values)
                  (kind, kind.label(l10n)),
              ],
              selected: _kind,
              onChanged: _setKind,
            ),
          ),
        const SizedBox(height: 28),
        Text(
          l10n.txAmount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.inkSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          liveRegion: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 8,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    MoneyFormat.amount(_amount),
                    style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1.9,
                      height: 1.05,
                      color: hasAmount ? colors.ink : colors.inkTertiary,
                    ),
                  ),
                ),
              ),
              Text(
                l10n.currencyLabel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
        if (widget.editPlanned == null) ...[
          const SizedBox(height: 16),
          // Raccourcis de la maquette : dicter ou écrire plutôt.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _Shortcut(
                icon: AppIcons.microphoneBold,
                label: l10n.txEmptyDictate,
                background: colors.primarySoft,
                foreground: colors.onPrimarySoft,
                onTap: () => context.pushReplacement(AppRoutes.quickEntry()),
              ),
              _Shortcut(
                icon: AppIcons.keyboard,
                label: l10n.txWriteWords,
                background: colors.chip,
                foreground: colors.ink,
                onTap: () =>
                    context.pushReplacement(AppRoutes.quickEntry(text: true)),
              ),
            ],
          ),
        ],
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              _AmountKeypad(onKey: _press),
              FilledButton(
                onPressed: hasAmount ? () => setState(() => _step = 2) : null,
                child: Text(l10n.txContinue),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailsStep(BuildContext context, List<Account> accounts) {
    final colors = context.colors;
    final l10n = context.l10n;
    final relative = RelativeDate(
      l10n,
      Localizations.localeOf(context).toLanguageTag(),
      ref.watch(clockProvider)(),
    );
    final from = _from(accounts);
    final to = _to(accounts, from);
    final isTransfer = _kind == TransactionKind.transfer;
    Account? byId(String? id) => accounts.where((a) => a.id == id).firstOrNull;
    String accountLabel(Account? a) => a?.name ?? '—';
    String? accountBalance(Account? a) =>
        a == null ? null : l10n.txAccountBalance(MoneyFormat.amount(a.balance));

    final canSave =
        !_saving &&
        (isTransfer ? to != null : _categoryId != null) &&
        from != null;
    final isPlanned = _isPlanned;
    final monthOf = ref.watch(monthOfProvider);
    final dueMonth = relative.month(monthOf(_due));
    final currentMonth = relative.month(monthOf(ref.watch(clockProvider)()));
    final nameError = _nameTried && _name.text.trim().isEmpty;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: colors.line)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Text(
                            _kind.label(l10n),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colors.inkSecondary,
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              text: '${MoneyFormat.amount(_amount)} ',
                              children: [
                                TextSpan(
                                  text: l10n.currencyLabel,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: colors.inkSecondary,
                                  ),
                                ),
                              ],
                            ),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -1,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _step = 1),
                      child: Text(l10n.txChange),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_kind == TransactionKind.expense &&
                  widget.editPlanned == null) ...[
                SegmentedChoice(
                  options: [
                    (false, l10n.txModePaid),
                    (true, l10n.txModePlanned),
                  ],
                  selected: _planned,
                  onChanged: (value) => setState(() => _planned = value),
                ),
                const SizedBox(height: 8),
                Text(
                  isPlanned ? l10n.txModePlannedHint : l10n.txModePaidHint,
                  style: TextStyle(fontSize: 13, color: colors.inkSecondary),
                ),
                const SizedBox(height: 20),
              ],
              if (isPlanned) ...[
                _SectionLabel(l10n.plannedName),
                TextField(
                  controller: _name,
                  maxLength: PlannedDraft.maxLength,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) {
                    if (_nameTried) setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: l10n.plannedNameHintExample,
                    counterText: '',
                    helperText: nameError ? null : l10n.plannedNameHint,
                    errorText: nameError ? l10n.plannedNameHint : null,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (isTransfer) ...[
                if (to == null)
                  _InfoBox(text: l10n.txNeedTwoAccounts)
                else ...[
                  _PickerRow(
                    icon: AppIcons.wallet,
                    label: l10n.txFrom,
                    value: accountLabel(byId(from)),
                    subtitle: accountBalance(byId(from)),
                    onTap: () => _chooseAccount(accounts, from, (id) {
                      _accountId = id;
                      if (id == _toAccountId) _toAccountId = null;
                    }),
                  ),
                  _PickerRow(
                    icon: AppIcons.wallet,
                    label: l10n.txTo,
                    value: accountLabel(byId(to)),
                    subtitle: accountBalance(byId(to)),
                    onTap: () => _chooseAccount(
                      accounts.where((a) => a.id != from).toList(),
                      to,
                      (id) => _toAccountId = id,
                    ),
                  ),
                ],
              ] else ...[
                _SectionLabel(l10n.txCategory),
                _CategoryPills(
                  kind: _kind,
                  selectedId: _categoryId,
                  onSelected: (id) => setState(() => _categoryId = id),
                ),
                const SizedBox(height: 20),
                _PickerRow(
                  icon: AppIcons.wallet,
                  label: l10n.txAccount,
                  value: accountLabel(byId(from)),
                  subtitle: accountBalance(byId(from)),
                  onTap: () =>
                      _chooseAccount(accounts, from, (id) => _accountId = id),
                ),
              ],
              if (isPlanned) ...[
                _PickerRow(
                  icon: AppIcons.calendarBlank,
                  label: l10n.plannedDueDate,
                  value: relative.longDate(_due),
                  onTap: _pickDue,
                  showDivider: false,
                ),
                const SizedBox(height: 8),
                _InfoBox(
                  text: dueMonth == currentMonth
                      ? l10n.plannedInfoSameMonth(dueMonth)
                      : l10n.plannedInfoLaterMonth(currentMonth, dueMonth),
                ),
              ] else
                _DayStrip(
                  label: relative.formDate(_date),
                  selected: _date,
                  now: ref.watch(clockProvider)(),
                  onOlder: _pickDate,
                  onPick: (day) => setState(() {
                    final now = ref.read(clockProvider)();
                    // On garde l'heure de saisie (ordre des opérations).
                    _date = DateTime(
                      day.year,
                      day.month,
                      day.day,
                      now.hour,
                      now.minute,
                    );
                  }),
                ),
              if (isTransfer && to != null) ...[
                const SizedBox(height: 8),
                _InfoBox(text: l10n.txTransferInfo),
              ],
              const SizedBox(height: 12),
              if (_descriptionOpen) ...[
                _SectionLabel(
                  isPlanned ? l10n.plannedNote : l10n.txDescription,
                ),
                TextField(
                  controller: _description,
                  autofocus: widget.editPlanned == null,
                  maxLength: TransactionDraft.maxDescriptionLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: isPlanned ? null : l10n.txDescriptionHint,
                    counterText: '',
                  ),
                ),
              ] else
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _descriptionOpen = true),
                    icon: const Icon(AppIcons.notePencil, size: 18),
                    label: Text(
                      isPlanned ? l10n.plannedAddNote : l10n.txAddDescription,
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.line)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canSave ? () => _save(accounts) : null,
              child: Text(
                widget.editPlanned != null
                    ? l10n.accountSave
                    : isPlanned
                    ? l10n.plannedSave
                    : _kind.saveLabel(l10n),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _chooseAccount(
    List<Account> accounts,
    String? selectedId,
    void Function(String id) apply,
  ) async {
    final id = await showAccountPicker(
      context,
      accounts: accounts,
      selectedId: selectedId,
    );
    if (id != null && mounted) setState(() => apply(id));
  }

  Widget _plannedSavedStep(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final saved = _savedPlanned!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final relative = RelativeDate(l10n, locale, ref.watch(clockProvider)());
    final month = relative.month(ref.watch(monthOfProvider)(saved.dueDate));
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.chip,
                  ),
                  child: Icon(
                    AppIcons.calendarBlank,
                    size: 32,
                    color: colors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                l10n.plannedSavedTitle(saved.name),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  text: '${MoneyFormat.amount(saved.amount)} ',
                  children: [
                    TextSpan(
                      text: l10n.currencyLabel,
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.inkSecondary,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppDateFormat.sentence(
                  l10n.plannedSavedMeta(
                    saved.accountName,
                    saved.category.name,
                    AppDateFormat.dayMonth(saved.dueDate, locale),
                  ),
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.inkSecondary),
              ),
              const SizedBox(height: 24),
              _InfoBox(text: l10n.plannedInfoSameMonth(month)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.go(AppRoutes.home),
                  icon: Icon(
                    AppIcons.calendarBlank,
                    size: 16,
                    color: colors.info,
                  ),
                  label: Text(l10n.txSeeInCalendar),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: colors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () => context.go(AppRoutes.plannedDetail(saved.id)),
                child: Text(l10n.plannedSeeExpense),
              ),
              TextButton(
                onPressed: _reset,
                style: TextButton.styleFrom(minimumSize: const Size(0, 52)),
                child: Text(l10n.txAddAnother),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _savedStep(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final saved = _saved!;
    final account = _savedAccount;
    final relative = RelativeDate(
      l10n,
      Localizations.localeOf(context).toLanguageTag(),
      ref.watch(clockProvider)(),
    );
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primarySoft,
                  ),
                  // Coche qui se trace (360 ms).
                  child: Center(
                    child: DrawnCheck(color: colors.onPrimarySoft, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                saved.kind.savedTitle(l10n),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  text: '${saved.signedAmount} ',
                  children: [
                    TextSpan(
                      text: l10n.currencyLabel,
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.inkSecondary,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${saved.meta(l10n)} · '
                '${RelativeDate.capitalize(relative.day(saved.occurredAt))}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.inkSecondary),
              ),
              if (saved.kind == TransactionKind.expense)
                if (saved.mainCategory case final category?)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BudgetImpactNote(mainCategoryId: category.id),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => context.go(AppRoutes.budgets),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(l10n.txSeeBudget),
                          ),
                        ),
                      ],
                    ),
                  ),
              if (account != null) ...[
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(color: colors.line),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.txNewBalance(account.name),
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.inkSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '${MoneyFormat.amount(account.balance)} '
                        '${l10n.currencyLabel}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(l10n.txBackHome),
              ),
              TextButton(
                onPressed: _reset,
                style: TextButton.styleFrom(minimumSize: const Size(0, 52)),
                child: Text(l10n.txAddAnother),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Clavier de saisie du montant (avec la touche « 000 »).
class _AmountKeypad extends StatelessWidget {
  const _AmountKeypad({required this.onKey});

  final ValueChanged<String> onKey;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['000', '0', 'del'],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      spacing: 6,
      children: [
        for (final row in _rows)
          Row(
            spacing: 6,
            children: [
              for (final key in row)
                Expanded(
                  child: Semantics(
                    button: true,
                    label: key == 'del'
                        ? MaterialLocalizations.of(context).deleteButtonTooltip
                        : key,
                    excludeSemantics: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onKey(key),
                      child: SizedBox(
                        height: 58,
                        child: Center(
                          child: key == 'del'
                              ? Icon(
                                  AppIcons.backspace,
                                  size: 24,
                                  color: colors.ink,
                                )
                              : Text(
                                  key,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _CategoryPills extends ConsumerWidget {
  const _CategoryPills({
    required this.kind,
    required this.selectedId,
    required this.onSelected,
  });

  final TransactionKind kind;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups =
        ref.watch(categoryGroupsProvider(kind.categoryKind!)).value ?? const [];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final group in groups)
          if (!group.category.isHidden || group.category.id == selectedId)
            ChoicePill(
              label: group.category.name,
              icon: categoryIcon(group.category.iconKey),
              height: 40,
              selected:
                  group.category.id == selectedId ||
                  group.children.any((c) => c.id == selectedId),
              onTap: () => onSelected(group.category.id),
            ),
      ],
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.showDivider = true,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool showDivider;

  /// Ligne discrète sous la valeur (« Solde 42 000 FCFA »).
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: showDivider
            ? BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.line)),
              )
            : null,
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.chip,
              ),
              child: Icon(icon, size: 17, color: colors.ink),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.inkSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.inkTertiary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(AppIcons.caretRight, size: 14, color: colors.inkTertiary),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: context.colors.inkSecondary,
      ),
    ),
  );
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.chip,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Icon(AppIcons.info, size: 17, color: colors.inkSecondary),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: colors.inkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aucun compte actif : on invite à en créer un.
class _NeedAccount extends StatelessWidget {
  const _NeedAccount({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: context.colors.inkSecondary),
        ),
        FilledButton(
          onPressed: () => context.pushReplacement(AppRoutes.newAccount),
          child: Text(context.l10n.accountsAdd),
        ),
      ],
    ),
  );
}

/// Raccourci pilule sous le montant (« Dicter », « Écrire avec mes mots »).
class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: background,
    shape: const StadiumBorder(),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Icon(icon, size: 15, color: foreground),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Date d'une opération déjà payée : les 7 derniers jours en pastilles ;
/// toucher le libellé ouvre le calendrier pour une date plus ancienne.
class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.label,
    required this.selected,
    required this.now,
    required this.onOlder,
    required this.onPick,
  });

  final String label;
  final DateTime selected;
  final DateTime now;
  final VoidCallback onOlder;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final relative = RelativeDate(l10n, locale, now);
    final today = CalendarDate.of(now);
    final picked = CalendarDate.of(selected.toLocal());
    final days = [
      for (var i = 6; i >= 0; i--)
        DateTime(today.year, today.month, today.day - i),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        InkWell(
          onTap: onOlder,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.txDate,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.inkSecondary,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          spacing: 6,
          children: [
            for (final day in days)
              Expanded(
                child: _DayChip(
                  top: day == today
                      ? l10n.txDayShortToday
                      : RelativeDate.capitalize(
                          DateFormat(
                            'E',
                            locale,
                          ).format(day).replaceAll('.', ''),
                        ),
                  number: '${day.day}',
                  semantics: relative.longDate(day),
                  selected: day == picked,
                  onTap: () => onPick(day),
                ),
              ),
          ],
        ),
        Text(
          l10n.txOlderDateHint,
          style: TextStyle(fontSize: 12.5, color: colors.inkTertiary),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.top,
    required this.number,
    required this.semantics,
    required this.selected,
    required this.onTap,
  });

  final String top;
  final String number;
  final String semantics;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ink = selected ? colors.onPrimarySoft : colors.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: semantics,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.primarySoft : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? colors.primaryMid : colors.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 2,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    top,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? ink : colors.inkTertiary,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    number,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
