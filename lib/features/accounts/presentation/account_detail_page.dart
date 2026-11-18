import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/clock.dart';
import '../../../core/errors/result.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/money/money.dart';
import '../../../core/time/month.dart';
import '../../../core/widgets/amount_display.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../l10n/l10n.dart';
import '../../goals/presentation/goals_providers.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_stats.dart';
import '../../transactions/presentation/transaction_labels.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../domain/account.dart';
import '../domain/account_draft.dart';
import 'account_labels.dart';
import 'accounts_providers.dart';

/// Détail d'un compte : solde, solde initial, archivage et suppression.
/// L'historique des mouvements arrivera avec la fonctionnalité Transactions.
class AccountDetailPage extends ConsumerWidget {
  const AccountDetailPage({required this.accountId, super.key});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final account = ref.watch(accountProvider(accountId));

    return switch (account) {
      AsyncData(value: final account?) => _AccountDetail(account: account),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.accountErrorNotFound)),
      ),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.errorGeneric)),
      ),
      _ => Scaffold(appBar: AppBar()),
    };
  }
}

class _AccountDetail extends ConsumerWidget {
  const _AccountDetail({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = ref.watch(clockProvider)();
    final relative = RelativeDate(l10n, locale, now);
    final month = Month.of(now);
    final history =
        ref.watch(accountTransactionsProvider(account.id)).value ?? const [];
    final balances = runningBalances(
      account.openingBalance,
      history,
      account.id,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.editAccount(account.id)),
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.chip,
                ),
                child: Icon(account.type.icon, size: 24, color: colors.ink),
              ),
              Text(
                l10n.accountTypeAndName(account.type.label(l10n), account.name),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.inkSecondary,
                ),
              ),
              AmountDisplay(amount: account.balance),
              if (ref.watch(reservedByAccountProvider).value?[account.id]
                  case final reserved?)
                Text(
                  l10n.accountAvailable(
                    // Négatif si de l'argent réservé a été dépensé depuis.
                    (account.balance - reserved).isNegative
                        ? MoneyFormat.signed(account.balance - reserved)
                        : MoneyFormat.amount(account.balance - reserved),
                    MoneyFormat.amount(reserved),
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: colors.inkSecondary),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _MonthFlow(
            flow: AccountMonthFlow.of(history, account.id, month),
            monthName: relative.month(month),
          ),
          const SizedBox(height: 10),
          if (account.isArchived)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                AppDateFormat.sentence(
                  l10n.accountArchivedInfo(
                    AppDateFormat.dayMonth(account.archivedAt!, locale),
                  ),
                ),
                style: _captionStyle(colors),
              ),
            ),
          Text(
            l10n.accountOpeningInfo(
              MoneyFormat.amount(account.openingBalance),
              AppDateFormat.dayMonthYear(account.createdAt, locale),
            ),
            style: _captionStyle(colors),
          ),
          if (!account.isArchived) ...[
            const SizedBox(height: 20),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push(
                      AppRoutes.newTransaction(accountId: account.id),
                    ),
                    icon: const Icon(AppIcons.plusBold, size: 18),
                    label: Text(l10n.accountNewOperation),
                  ),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      AppRoutes.newTransaction(
                        kind: TransactionKind.transfer,
                        accountId: account.id,
                      ),
                    ),
                    icon: const Icon(AppIcons.arrowsLeftRight, size: 18),
                    label: Text(l10n.accountNewTransfer),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          Semantics(
            header: true,
            child: Text(
              l10n.accountHistory,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.accountNoHistory,
                style: TextStyle(fontSize: 14, color: colors.inkSecondary),
              ),
            ),
          for (final (day, items) in groupByDay(history)) ...[
            DayHeader(relative.header(day)),
            for (final t in items)
              _HistoryRow(
                transaction: t,
                accountId: account.id,
                balanceAfter: balances[t.id],
              ),
          ],
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 8),
          if (account.isArchived)
            _ActionButton(
              icon: AppIcons.arrowCounterClockwise,
              label: l10n.accountRestore,
              color: colors.ink,
              onPressed: () => _restore(context, ref),
            )
          else
            _ActionButton(
              icon: AppIcons.archive,
              label: l10n.accountArchive,
              color: colors.ink,
              onPressed: () => _archive(context, ref),
            ),
          _ActionButton(
            icon: AppIcons.trash,
            label: l10n.accountDelete,
            color: colors.negative,
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
    );
  }

  TextStyle _captionStyle(AppColors colors) =>
      TextStyle(fontSize: 12.5, height: 1.45, color: colors.inkTertiary);

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.accountArchiveTitle(account.name),
      message: l10n.accountArchiveBody,
      confirmLabel: l10n.accountArchiveConfirm,
    );
    if (!confirmed || !context.mounted) return;

    final result = await ref
        .read(accountsRepositoryProvider)
        .archive(account.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        context.go(AppRoutes.accounts);
      case Err():
        _showMessage(context, l10n.errorGeneric);
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final result = await ref
        .read(accountsRepositoryProvider)
        .restore(account.id);
    if (!context.mounted) return;
    _showMessage(context, switch (result) {
      Ok() => l10n.accountRestored,
      Err(failure: ValidationFailure<AccountFieldError>()) =>
        l10n.accountRestoreNameTaken,
      Err() => l10n.errorGeneric,
    });
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.accountDeleteTitle(account.name),
      message: account.isArchived
          ? l10n.accountDeleteBodyArchived
          : account.operationCount > 0
          ? l10n.accountDeleteBodyWithOperations(
              account.operationCount,
              MoneyFormat.amount(account.balance),
            )
          : l10n.accountDeleteBody(MoneyFormat.amount(account.balance)),
      confirmLabel: l10n.accountDeleteConfirm,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final result = await ref
        .read(accountsRepositoryProvider)
        .delete(account.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        context.go(AppRoutes.accounts);
      case Err():
        _showMessage(context, l10n.errorGeneric);
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// « Arrivées en novembre » / « Sorties en novembre », et la part des
/// transferts (exclue des revenus et dépenses).
class _MonthFlow extends StatelessWidget {
  const _MonthFlow({required this.flow, required this.monthName});

  final AccountMonthFlow flow;
  final String monthName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    Widget cell(
      String label,
      String amount,
      EdgeInsets padding, {
      Color? color,
    }) => Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 3,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.5, color: colors.inkSecondary),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color ?? colors.ink,
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: colors.line),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: colors.line)),
                    ),
                    child: cell(
                      l10n.accountMonthIn(monthName),
                      MoneyFormat.signed(flow.incoming),
                      const EdgeInsets.fromLTRB(0, 14, 14, 14),
                      color: colors.inkSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: cell(
                    l10n.accountMonthOut(monthName),
                    MoneyFormat.signed(-flow.outgoing),
                    const EdgeInsets.fromLTRB(14, 14, 0, 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (flow.transfers.value > 0)
          Text(
            l10n.accountTransfersNote(MoneyFormat.amount(flow.transfers)),
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: colors.inkTertiary,
            ),
          ),
      ],
    );
  }
}

/// Mouvement de l'historique d'un compte : effet sur ce compte et solde après.
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.transaction,
    required this.accountId,
    required this.balanceAfter,
  });

  final Transaction transaction;
  final String accountId;
  final Money? balanceAfter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final t = transaction;
    final effect = t.effectOn(accountId);
    return InkWell(
      onTap: () => context.push(AppRoutes.transactionDetail(t.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    t.title(l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    t.isTransfer
                        ? l10n.accountInternalTransfer
                        : t.mainCategory?.name ?? '',
                    style: TextStyle(fontSize: 12.5, color: colors.inkTertiary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 2,
              children: [
                Text(
                  MoneyFormat.signed(effect),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: t.isTransfer
                        ? colors.inkSecondary
                        : effect.isNegative
                        ? colors.ink
                        : colors.positive,
                  ),
                ),
                if (balanceAfter != null)
                  Text(
                    l10n.accountBalanceAfterShort(
                      MoneyFormat.amount(balanceAfter!),
                    ),
                    style: TextStyle(fontSize: 12, color: colors.inkTertiary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(0, 44),
        ),
      ),
    );
  }
}
