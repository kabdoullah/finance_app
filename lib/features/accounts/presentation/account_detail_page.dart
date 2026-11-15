import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/errors/result.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/amount_display.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../l10n/l10n.dart';
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
            ],
          ),
          const SizedBox(height: 20),
          if (account.isArchived)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.accountArchivedInfo(
                  AppDateFormat.dayMonth(account.archivedAt!, locale),
                ),
                textAlign: TextAlign.center,
                style: _captionStyle(colors),
              ),
            ),
          Text(
            l10n.accountOpeningInfo(
              MoneyFormat.amount(account.openingBalance),
              AppDateFormat.dayMonthYear(account.createdAt, locale),
            ),
            textAlign: TextAlign.center,
            style: _captionStyle(colors),
          ),
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
          : l10n.accountDeleteBody(MoneyFormat.amount(account.balance)),
      confirmLabel: l10n.accountDeleteConfirm,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final result = await ref.read(accountsRepositoryProvider).delete(account.id);
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
