import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/clock.dart';
import '../../../core/errors/result.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/segmented_choice.dart';
import '../../../l10n/l10n.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/account_picker_sheet.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../categories/presentation/category_icons.dart';
import '../domain/transaction.dart';
import '../domain/transaction_draft.dart';
import 'transaction_labels.dart';
import 'transactions_providers.dart';

/// Ajout d'une opération en 3 étapes (maquette Ajout-Transaction) :
/// 1. type et montant, 2. détails, 3. confirmation.
class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({
    required this.initialKind,
    this.initialAccountId,
    super.key,
  });

  final TransactionKind initialKind;
  final String? initialAccountId;

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  static const _maxDigits = 9;

  final _description = TextEditingController();

  int _step = 1;
  late TransactionKind _kind = widget.initialKind;
  String _digits = '';
  String? _categoryId;
  String? _accountId;
  String? _toAccountId;
  late DateTime _date;
  bool _descriptionOpen = false;
  bool _saving = false;

  /// Étape 3 : opération enregistrée et nouveau solde du compte concerné.
  Transaction? _saved;
  Account? _savedAccount;

  Money get _amount => _digits.isEmpty ? Money.zero : Money(int.parse(_digits));

  @override
  void initState() {
    super.initState();
    _date = ref.read(clockProvider)();
    _accountId = widget.initialAccountId;
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
    super.dispose();
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

  void _reset() => setState(() {
    _step = 1;
    _digits = '';
    _categoryId = null;
    _description.clear();
    _descriptionOpen = false;
    _saved = null;
    _date = ref.read(clockProvider)();
  });

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
        title: Text(_step == 3 ? l10n.txSavedTitle : l10n.txNewTitle),
      ),
      body: SafeArea(
        child: switch (accounts) {
          null => const SizedBox.shrink(),
          [] => _NeedAccount(message: l10n.txNeedAccount),
          _ => switch (_step) {
            1 => _amountStep(context),
            2 => _detailsStep(context, accounts),
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
    String accountLabel(Account? a) => a == null
        ? '—'
        : '${a.name} · ${MoneyFormat.amount(a.balance)} ${l10n.currencyLabel}';

    final canSave =
        !_saving &&
        (isTransfer ? to != null : _categoryId != null) &&
        from != null;

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
              if (isTransfer) ...[
                if (to == null)
                  _InfoBox(text: l10n.txNeedTwoAccounts)
                else ...[
                  _PickerRow(
                    icon: AppIcons.wallet,
                    label: l10n.txFrom,
                    value: accountLabel(byId(from)),
                    onTap: () => _chooseAccount(accounts, from, (id) {
                      _accountId = id;
                      if (id == _toAccountId) _toAccountId = null;
                    }),
                  ),
                  _PickerRow(
                    icon: AppIcons.wallet,
                    label: l10n.txTo,
                    value: accountLabel(byId(to)),
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
                  onTap: () =>
                      _chooseAccount(accounts, from, (id) => _accountId = id),
                ),
              ],
              _PickerRow(
                icon: AppIcons.calendarBlank,
                label: l10n.txDate,
                value: relative.formDate(_date),
                onTap: _pickDate,
                showDivider: false,
              ),
              if (isTransfer && to != null) ...[
                const SizedBox(height: 8),
                _InfoBox(text: l10n.txTransferInfo),
              ],
              const SizedBox(height: 12),
              if (_descriptionOpen) ...[
                _SectionLabel(l10n.txDescription),
                TextField(
                  controller: _description,
                  autofocus: true,
                  maxLength: TransactionDraft.maxDescriptionLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l10n.txDescriptionHint,
                    counterText: '',
                  ),
                ),
              ] else
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _descriptionOpen = true),
                    icon: const Icon(AppIcons.notePencil, size: 18),
                    label: Text(l10n.txAddDescription),
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
              child: Text(_kind.saveLabel(l10n)),
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
                  child: Icon(
                    AppIcons.checkBold,
                    size: 32,
                    color: colors.onPrimarySoft,
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
          ChoicePill(
            label: group.category.name,
            icon: categoryIcon(group.category.iconKey),
            height: 40,
            selected: group.category.id == selectedId,
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
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool showDivider;

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
