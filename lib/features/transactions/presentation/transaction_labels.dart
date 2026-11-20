import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/l10n.dart';
import '../../categories/presentation/category_icons.dart';
import '../domain/transaction.dart';

extension TransactionKindLabels on TransactionKind {
  String label(AppLocalizations l10n) => switch (this) {
    TransactionKind.expense => l10n.txKindExpense,
    TransactionKind.income => l10n.txKindIncome,
    TransactionKind.transfer => l10n.txKindTransfer,
  };

  String hint(AppLocalizations l10n) => switch (this) {
    TransactionKind.expense => l10n.txKindExpenseHint,
    TransactionKind.income => l10n.txKindIncomeHint,
    TransactionKind.transfer => l10n.txKindTransferHint,
  };

  String saveLabel(AppLocalizations l10n) => switch (this) {
    TransactionKind.expense => l10n.txSaveExpense,
    TransactionKind.income => l10n.txSaveIncome,
    TransactionKind.transfer => l10n.txSaveTransfer,
  };

  String savedTitle(AppLocalizations l10n) => switch (this) {
    TransactionKind.expense => l10n.txSavedExpense,
    TransactionKind.income => l10n.txSavedIncome,
    TransactionKind.transfer => l10n.txSavedTransfer,
  };

  IconData get icon => switch (this) {
    TransactionKind.expense => AppIcons.arrowUpRight,
    TransactionKind.income => AppIcons.arrowDownLeft,
    TransactionKind.transfer => AppIcons.arrowsLeftRight,
  };
}

extension EntryMethodLabel on EntryMethod {
  String label(AppLocalizations l10n) => switch (this) {
    EntryMethod.manual => l10n.entryManual,
    EntryMethod.voice => l10n.entryVoice,
    EntryMethod.text => l10n.entryText,
    EntryMethod.receipt => l10n.entryReceipt,
    EntryMethod.recurring => l10n.entryRecurring,
  };
}

extension TransactionLabels on Transaction {
  /// Description, sinon catégorie choisie, sinon « Vers Wave ».
  String title(AppLocalizations l10n) =>
      description ??
      (isTransfer
          ? l10n.txTransferTitle(toAccountName ?? '')
          : category?.name ?? '');

  /// « Transport · Wave » ou « Transfert · Ecobank → Wave ».
  String meta(AppLocalizations l10n) => isTransfer
      ? l10n.txTransferMeta(accountName, toAccountName ?? '')
      : l10n.txMeta(mainCategory?.name ?? '', accountName);

  IconData get icon => isTransfer
      ? AppIcons.arrowsLeftRight
      : categoryIcon(mainCategory?.iconKey ?? '');

  /// « −2 500 », « +45 000 », ou « 25 000 » pour un transfert.
  String get signedAmount => switch (kind) {
    TransactionKind.expense => MoneyFormat.signed(-amount),
    TransactionKind.income => MoneyFormat.signed(amount),
    TransactionKind.transfer => MoneyFormat.amount(amount),
  };

  Color amountColor(AppColors colors) => switch (kind) {
    TransactionKind.income => colors.positive,
    TransactionKind.transfer => colors.inkSecondary,
    TransactionKind.expense => colors.ink,
  };

  (Color background, Color foreground) iconColors(AppColors colors) =>
      switch (kind) {
        TransactionKind.income => (colors.primarySoft, colors.onPrimarySoft),
        TransactionKind.transfer => (colors.chip, colors.inkSecondary),
        TransactionKind.expense => (colors.chip, colors.ink),
      };
}

/// Regroupe des opérations (déjà triées) par jour local.
List<(DateTime, List<Transaction>)> groupByDay(List<Transaction> transactions) {
  final groups = <(DateTime, List<Transaction>)>[];
  for (final t in transactions) {
    final local = t.occurredAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    if (groups.isEmpty || groups.last.$1 != day) groups.add((day, []));
    groups.last.$2.add(t);
  }
  return groups;
}

/// Ligne d'opération (liste, accueil).
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    this.onTap,
    this.masked = false,
    super.key,
  });

  final Transaction transaction;
  final VoidCallback? onTap;

  /// Montant remplacé par « •••• ».
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final (iconBg, iconFg) = transaction.iconColors(colors);
    return PressScale(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            spacing: 12,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBg,
                ),
                child: Icon(transaction.icon, size: 18, color: iconFg),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      transaction.title(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      transaction.meta(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.inkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                masked ? MoneyFormat.masked : transaction.signedAmount,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: transaction.amountColor(colors),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// En-tête de jour des listes (« Aujourd'hui · 15 nov. »).
class DayHeader extends StatelessWidget {
  const DayHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 4),
    child: Semantics(
      header: true,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: context.colors.inkTertiary,
        ),
      ),
    ),
  );
}
