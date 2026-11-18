import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/clock.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/amount_display.dart';
import '../../../l10n/l10n.dart';
import '../../goals/presentation/goals_page.dart';
import '../domain/account.dart';
import '../domain/account_type.dart';
import '../domain/accounts_summary.dart';
import 'account_labels.dart';
import 'accounts_providers.dart';

/// « Mes comptes » : total, répartition, comptes par type, archivés.
class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final active = ref.watch(activeAccountsProvider);
    final archived = ref.watch(archivedAccountsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountsTitle),
        actions: [
          IconButton(
            tooltip: l10n.accountsAdd,
            icon: const Icon(AppIcons.plusBold, size: 20),
            onPressed: () => context.push(AppRoutes.newAccount),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: switch (active) {
        AsyncData(:final value) => _AccountsList(
          active: value,
          archived: archived,
        ),
        AsyncError() => Center(child: Text(l10n.errorGeneric)),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _AccountsList extends StatelessWidget {
  const _AccountsList({required this.active, required this.archived});

  final List<Account> active;
  final List<Account> archived;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = AccountsSummary.of(active);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      children: [
        _TotalHeader(summary: summary),
        if (summary.shares.isNotEmpty) ...[
          const SizedBox(height: 20),
          _DistributionBar(shares: summary.shares),
        ],
        if (active.isEmpty && archived.isEmpty) ...[
          const SizedBox(height: 28),
          Text(
            l10n.accountsEmpty,
            style: TextStyle(fontSize: 14, color: context.colors.inkSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push(AppRoutes.newAccount),
            child: Text(l10n.accountsAdd),
          ),
        ] else
          for (final type in accountTypeListOrder)
            ..._typeGroup(context, type, summary),
        if (archived.isNotEmpty) ...[
          const SizedBox(height: 28),
          _GroupHeader(
            label: l10n.accountsArchived,
            trailing: '${archived.length}',
          ),
          for (final account in archived) _AccountTile(account: account),
        ],
        if (active.isNotEmpty) ...[
          const SizedBox(height: 20),
          const GoalsAccountsLink(),
        ],
      ],
    );
  }

  List<Widget> _typeGroup(
    BuildContext context,
    AccountType type,
    AccountsSummary summary,
  ) {
    final l10n = context.l10n;
    final accounts = active.where((a) => a.type == type).toList();
    // Seul le groupe Épargne vide est montré, pour inviter à en créer un.
    if (accounts.isEmpty && type != AccountType.savings) return const [];

    return [
      const SizedBox(height: 28),
      _GroupHeader(
        label: type.label(l10n),
        trailing: accounts.isEmpty
            ? '—'
            : MoneyFormat.amount(summary.subtotals[type] ?? Money.zero),
      ),
      if (accounts.isEmpty)
        const _AddSavingsTile()
      else
        for (final account in accounts) _AccountTile(account: account),
    ];
  }
}

class _TotalHeader extends StatelessWidget {
  const _TotalHeader({required this.summary});

  final AccountsSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Text(
          l10n.accountsTotal,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.inkSecondary,
          ),
        ),
        AmountDisplay(amount: summary.total),
        Text(
          l10n.accountsCount(summary.count),
          style: TextStyle(fontSize: 13, color: colors.inkTertiary),
        ),
      ],
    );
  }
}

/// Une seule barre empilée + légende chiffrée (pas de lecture d'angle).
class _DistributionBar extends StatelessWidget {
  const _DistributionBar({required this.shares});

  final List<AccountShare> shares;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final labels = [
      for (final share in shares)
        l10n.accountsShare(
          share.account?.name ?? l10n.accountsOthers,
          share.percent,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Semantics(
          label: l10n.accountsDistribution(labels.join(', ')),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Row(
                // Sans enfant, un ColoredBox prend la hauteur minimale
                // permise : on étire les segments sur les 10 px de la barre.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 2,
                children: [
                  for (final (i, share) in shares.indexed)
                    if (share.percent > 0)
                      Expanded(
                        flex: share.percent,
                        child: ColoredBox(color: colors.chart[i]),
                      ),
                ],
              ),
            ),
          ),
        ),
        ExcludeSemantics(
          child: Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final (i, label) in labels.indexed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.chart[i],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const SizedBox.square(dimension: 8),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.inkSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.trailing});

  final String label;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: context.colors.inkTertiary,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        header: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label.toUpperCase(), style: style),
            Text(trailing, style: style),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final archived = account.isArchived;
    final lastOperation = account.lastOperationAt;
    final subtitle = archived
        ? l10n.accountArchivedOn(
            AppDateFormat.dayMonth(account.archivedAt!, locale),
          )
        : lastOperation == null
        ? l10n.accountNoOperation
        : l10n.accountLastOperation(
            RelativeDate(
              l10n,
              locale,
              ref.watch(clockProvider)(),
            ).day(lastOperation),
          );

    final tile = InkWell(
      onTap: () => context.go(AppRoutes.accountDetail(account.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          spacing: 12,
          children: [
            _IconCircle(icon: archived ? AppIcons.archive : account.type.icon),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: colors.inkTertiary),
                  ),
                ],
              ),
            ),
            Text(
              MoneyFormat.amount(account.balance),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            Icon(AppIcons.caretRight, size: 14, color: colors.inkTertiary),
          ],
        ),
      ),
    );
    return archived ? Opacity(opacity: 0.6, child: tile) : tile;
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(shape: BoxShape.circle, color: colors.chip),
      child: Icon(icon, size: 18, color: colors.ink),
    );
  }
}

/// Encart pointillé « Ajouter un compte épargne » (groupe Épargne vide).
class _AddSavingsTile extends StatelessWidget {
  const _AddSavingsTile();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final radius = BorderRadius.circular(14);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: CustomPaint(
        foregroundPainter: _DashedBorderPainter(color: colors.line, radius: 14),
        child: InkWell(
          borderRadius: radius,
          onTap: () => context.push(AppRoutes.newAccount),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              spacing: 12,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primarySoft,
                  ),
                  child: Icon(
                    AppIcons.piggyBank,
                    size: 17,
                    color: colors.onPrimarySoft,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        l10n.accountsAddSavings,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n.accountsAddSavingsHint,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.inkTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(AppIcons.plusBold, size: 16, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(0.5),
      );
    const dash = 4.0;
    const gap = 3.0;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
