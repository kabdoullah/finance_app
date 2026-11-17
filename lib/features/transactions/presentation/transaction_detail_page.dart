import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/clock.dart';
import '../../../core/errors/result.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/money/amount_input_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../l10n/l10n.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_icons.dart';
import '../domain/transaction.dart';
import '../domain/transaction_draft.dart';
import '../domain/transaction_stats.dart';
import 'transaction_labels.dart';
import 'transactions_providers.dart';

/// Détail d'une opération : consultation, modification, suppression annulable.
class TransactionDetailPage extends ConsumerStatefulWidget {
  const TransactionDetailPage({required this.transactionId, super.key});

  final String transactionId;

  @override
  ConsumerState<TransactionDetailPage> createState() =>
      _TransactionDetailPageState();
}

class _TransactionDetailPageState extends ConsumerState<TransactionDetailPage> {
  /// Opération supprimée, gardée en mémoire pour « Annuler la suppression ».
  Transaction? _deleted;

  /// Brouillon en cours de modification (`null` = consultation).
  TransactionDraft? _draft;
  final _amount = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  void _startEdit(Transaction t) => setState(() {
    _draft = TransactionDraft.from(t);
    _amount.text = MoneyFormat.amount(t.amount);
    _description.text = t.description ?? '';
  });

  Future<void> _saveEdit() async {
    final draft = _draft!.copyWith(
      amount: AmountInputFormatter.parse(_amount.text),
      description: _description.text,
    );
    final result = await ref
        .read(transactionsRepositoryProvider)
        .update(widget.transactionId, draft);
    if (!mounted) return;
    switch (result) {
      case Ok():
        setState(() => _draft = null);
      case Err(failure: ValidationFailure<TransactionFieldError>(:final errors))
          when errors.contains(TransactionFieldError.accountUnavailable):
        _showMessage(context.l10n.txAccountUnavailable);
      case Err():
        _showMessage(context.l10n.errorGeneric);
    }
  }

  Future<void> _duplicate() async {
    final result = await ref
        .read(transactionsRepositoryProvider)
        .duplicate(widget.transactionId);
    if (!mounted) return;
    _showMessage(switch (result) {
      Ok() => context.l10n.txDuplicated,
      Err() => context.l10n.errorGeneric,
    });
  }

  Future<void> _delete(Transaction t) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.txDeleteTitle(t.kind.storageValue),
      message: l10n.txDeleteBody(
        t.title(l10n),
        MoneyFormat.amount(t.amount),
        t.accountName,
      ),
      confirmLabel: l10n.txDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final result = await ref.read(transactionsRepositoryProvider).delete(t.id);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _deleted = value);
      case Err():
        _showMessage(l10n.errorGeneric);
    }
  }

  Future<void> _undo() async {
    final result = await ref
        .read(transactionsRepositoryProvider)
        .restore(_deleted!);
    if (!mounted) return;
    switch (result) {
      case Ok():
        setState(() => _deleted = null);
      case Err():
        _showMessage(context.l10n.errorGeneric);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final deleted = _deleted;
    if (deleted != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.txDetailTitle)),
        body: _DeletedView(transaction: deleted, onUndo: _undo),
      );
    }

    final transaction = ref.watch(transactionProvider(widget.transactionId));
    return switch (transaction) {
      AsyncData(value: final t?) =>
        _draft == null ? _view(context, t) : _edit(context),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.txNotFound)),
      ),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.errorGeneric)),
      ),
      _ => Scaffold(appBar: AppBar()),
    };
  }

  Widget _view(BuildContext context, Transaction t) {
    final colors = context.colors;
    final l10n = context.l10n;
    final relative = RelativeDate(
      l10n,
      Localizations.localeOf(context).toLanguageTag(),
      ref.watch(clockProvider)(),
    );

    // « Solde après » : solde du compte débité/crédité juste après l'opération.
    final account = ref.watch(accountProvider(t.accountId)).value;
    final history = ref.watch(accountTransactionsProvider(t.accountId)).value;
    final balanceAfter = account == null || history == null
        ? null
        : runningBalances(account.openingBalance, history, t.accountId)[t.id];
    final balanceLine = balanceAfter == null
        ? null
        : l10n.txBalanceAfter(MoneyFormat.amount(balanceAfter));

    final (iconBg, iconFg) = t.iconColors(colors);
    final category = t.category;
    final parent = t.parentCategory;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.txDetailTitle),
        actions: [
          TextButton(
            onPressed: () => _startEdit(t),
            child: Text(l10n.accountEditAction),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        children: [
          Column(
            spacing: 8,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBg,
                ),
                child: Icon(t.icon, size: 24, color: iconFg),
              ),
              Text(
                t.title(l10n),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text.rich(
                TextSpan(
                  text: '${t.signedAmount} ',
                  children: [
                    TextSpan(
                      text: l10n.currencyLabel,
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.inkSecondary,
                      ),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1.3,
                  height: 1,
                  color: t.kind == TransactionKind.income
                      ? colors.positive
                      : colors.ink,
                ),
              ),
              Text(
                l10n.txKindWhen(
                  t.kind.label(l10n),
                  relative.dayAndTime(t.occurredAt),
                ),
                style: TextStyle(fontSize: 13, color: colors.inkSecondary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (t.isTransfer) ...[
            _InfoRow(
              label: l10n.txFrom,
              value: t.accountName,
              secondary: balanceLine,
            ),
            _InfoRow(label: l10n.txTo, value: t.toAccountName ?? ''),
          ] else ...[
            _InfoRow(
              label: l10n.txCategory,
              value: parent == null
                  ? category?.name ?? ''
                  : '${parent.name} › ${category?.name}',
            ),
            _InfoRow(
              label: l10n.txAccount,
              value: t.accountName,
              secondary: balanceLine,
            ),
          ],
          _InfoRow(label: l10n.txDate, value: relative.longDate(t.occurredAt)),
          if (t.description != null)
            _InfoRow(label: l10n.txDescription, value: t.description!),
          _InfoRow(label: l10n.txEntry, value: t.entryMethod.label(l10n)),
          const SizedBox(height: 16),
          _ActionRow(
            icon: AppIcons.copy,
            label: l10n.txDuplicate,
            color: colors.ink,
            onTap: _duplicate,
          ),
          _ActionRow(
            icon: AppIcons.trash,
            label: l10n.txDelete,
            color: colors.negative,
            onTap: () => _delete(t),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _edit(BuildContext context) {
    final l10n = context.l10n;
    final draft = _draft!;
    final accounts = ref.watch(activeAccountsProvider).value ?? const [];
    final categoryKind = draft.kind.categoryKind;
    final List<CategoryGroup> groups = categoryKind == null
        ? const []
        : ref.watch(categoryGroupsProvider(categoryKind)).value ?? const [];

    // Catégorie principale sélectionnée (le brouillon peut pointer une
    // sous-catégorie).
    final selectedGroup = groups
        .where(
          (g) =>
              g.category.id == draft.categoryId ||
              g.children.any((c) => c.id == draft.categoryId),
        )
        .firstOrNull;

    void update(TransactionDraft Function(TransactionDraft d) change) =>
        setState(() => _draft = change(_draft!));

    return Scaffold(
      appBar: AppBar(
        leading: CloseButton(onPressed: () => setState(() => _draft = null)),
        title: Text(l10n.txDetailTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                children: [
                  _Label(l10n.txAmount),
                  TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [AmountInputFormatter(maxDigits: 9)],
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(suffixText: l10n.currencyLabel),
                  ),
                  const SizedBox(height: 20),
                  _Label(l10n.txDescription),
                  TextField(
                    controller: _description,
                    maxLength: TransactionDraft.maxDescriptionLength,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(counterText: ''),
                  ),
                  const SizedBox(height: 20),
                  if (draft.kind == TransactionKind.transfer) ...[
                    _Label(l10n.txFrom),
                    _AccountPills(
                      accounts: accounts,
                      selectedId: draft.accountId,
                      onSelected: (id) =>
                          update((d) => d.copyWith(accountId: id)),
                    ),
                    const SizedBox(height: 20),
                    _Label(l10n.txTo),
                    _AccountPills(
                      accounts: accounts,
                      selectedId: draft.toAccountId,
                      onSelected: (id) =>
                          update((d) => d.copyWith(toAccountId: id)),
                    ),
                  ] else ...[
                    _Label(l10n.txCategory),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final group in groups)
                          ChoicePill(
                            label: group.category.name,
                            icon: categoryIcon(group.category.iconKey),
                            selected: group == selectedGroup,
                            onTap: () => update(
                              (d) => d.copyWith(categoryId: group.category.id),
                            ),
                          ),
                      ],
                    ),
                    if (selectedGroup != null &&
                        selectedGroup.children.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _Label(l10n.txSubcategory),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoicePill(
                            label: l10n.txNoSubcategory,
                            selected:
                                draft.categoryId == selectedGroup.category.id,
                            onTap: () => update(
                              (d) => d.copyWith(
                                categoryId: selectedGroup.category.id,
                              ),
                            ),
                          ),
                          for (final child in selectedGroup.children)
                            ChoicePill(
                              label: child.name,
                              selected: draft.categoryId == child.id,
                              onTap: () => update(
                                (d) => d.copyWith(categoryId: child.id),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    _Label(l10n.txAccount),
                    _AccountPills(
                      accounts: accounts,
                      selectedId: draft.accountId,
                      onSelected: (id) =>
                          update((d) => d.copyWith(accountId: id)),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.colors.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 6,
                children: [
                  FilledButton(
                    onPressed:
                        AmountInputFormatter.parse(_amount.text).value > 0
                        ? _saveEdit
                        : null,
                    child: Text(l10n.accountSave),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _draft = null),
                    style: TextButton.styleFrom(minimumSize: const Size(0, 52)),
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountPills extends StatelessWidget {
  const _AccountPills({
    required this.accounts,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final account in accounts)
        ChoicePill(
          label: account.name,
          selected: account.id == selectedId,
          onTap: () => onSelected(account.id),
        ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.secondary});

  final String label;
  final String value;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: colors.inkSecondary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 2,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (secondary != null)
                  Text(
                    secondary!,
                    style: TextStyle(fontSize: 12.5, color: colors.inkTertiary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: showDivider
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: context.colors.line)),
            )
          : null,
      child: Row(
        spacing: 12,
        children: [
          Icon(icon, size: 18, color: color),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
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

class _DeletedView extends StatelessWidget {
  const _DeletedView({required this.transaction, required this.onUndo});

  final Transaction transaction;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.chip,
            ),
            child: Icon(AppIcons.trash, size: 26, color: colors.inkSecondary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.txDeletedTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.txDeletedBody(transaction.accountName),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: colors.inkSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: onUndo,
            icon: const Icon(AppIcons.arrowCounterClockwise, size: 18),
            label: Text(l10n.txUndo),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () => context.go(AppRoutes.transactions),
            child: Text(l10n.txBackToList),
          ),
        ),
      ],
    );
  }
}
