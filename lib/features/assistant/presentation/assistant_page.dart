import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/clock.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/l10n.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_providers.dart';
import '../../quick_entry/domain/quick_entry_parser.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/assistant_reply.dart';
import 'ai_model_controller.dart';
import 'assistant_controller.dart';

/// Onglet Assistant (maquettes Assistant, Assistant-Chargement,
/// Assistant-SansIA) : le Copilote répond avec des chiffres calculés par
/// l'application et expliqués par Gemma.
class AssistantPage extends ConsumerWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final ai = ref.watch(aiModelControllerProvider);
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.asTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              l10n.asSubtitle,
              style: TextStyle(fontSize: 12.5, color: colors.inkTertiary),
            ),
          ],
        ),
      ),
      body: ai.status == AiModelStatus.ready
          ? const _Conversation()
          : _NotLoaded(state: ai),
    );
  }
}

/// Questions proposées en pastilles.
List<String> _suggestions(AppLocalizations l10n) => [
  l10n.asSuggestSave,
  l10n.asSuggest2,
  l10n.asSuggest3,
  l10n.asSuggestGoal,
  l10n.asSuggest5,
];

class _Conversation extends ConsumerStatefulWidget {
  const _Conversation();

  @override
  ConsumerState<_Conversation> createState() => _ConversationState();
}

class _ConversationState extends ConsumerState<_Conversation> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  /// Messages déjà là à l'ouverture (historique) : seuls les suivants
  /// glissent en arrivant.
  late final int _initialEntries = ref
      .read(assistantControllerProvider)
      .entries
      .length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _takeRequest());
  }

  /// Question demandée ailleurs (« En parler au Copilote »).
  void _takeRequest() {
    if (!mounted) return;
    final question = ref.read(assistantRequestProvider.notifier).take();
    if (question != null) _send(question);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final question = text ?? _input.text;
    if (question.trim().isEmpty) return;
    _input.clear();
    FocusScope.of(context).unfocus();
    ref.read(assistantControllerProvider.notifier).ask(question);
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  });

  static Widget _entry(ChatEntry entry) => switch (entry) {
    UserEntry(:final text) => _UserBubble(text: text),
    final ReplyEntry reply => _ReplyBubble(reply: reply),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final state = ref.watch(assistantControllerProvider);
    ref
      ..listen(assistantControllerProvider, (_, _) => _scrollToEnd())
      ..listen(assistantRequestProvider, (_, next) {
        if (next != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _takeRequest());
        }
      });

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              if (state.entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.asIntro,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: colors.inkSecondary,
                    ),
                  ),
                ),
              for (final (i, entry) in state.entries.indexed)
                if (i < _initialEntries)
                  _entry(entry)
                else
                  FadeSlideIn(key: ValueKey(i), child: _entry(entry)),
              if (state.busy) const _Typing(),
            ],
          ),
        ),
        if (!state.busy)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final suggestion in _suggestions(l10n))
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: ActionChip(
                      label: Text(suggestion),
                      onPressed: () => _send(suggestion),
                    ),
                  ),
              ],
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    enabled: !state.busy,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(hintText: l10n.asInputHint),
                  ),
                ),
                IconButton.filled(
                  tooltip: l10n.asSend,
                  onPressed: state.busy ? null : _send,
                  icon: const Icon(AppIcons.arrowUpBold, size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 12, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 15, color: colors.onPrimarySoft),
        ),
      ),
    );
  }
}

class _ReplyBubble extends StatelessWidget {
  const _ReplyBubble({required this.reply});

  final ReplyEntry reply;

  void _open(BuildContext context, ReplyLink link) => switch (link.target) {
    ReplyLinkTarget.transactions => context.go(AppRoutes.transactions),
    ReplyLinkTarget.budgets => context.go(AppRoutes.budgets),
    ReplyLinkTarget.accounts => context.push(AppRoutes.accounts),
    ReplyLinkTarget.forecast => context.go(AppRoutes.forecast),
    ReplyLinkTarget.simulation => context.go(
      AppRoutes.simulationFor(
        label: link.simulationLabel,
        price: link.simulationPrice,
      ),
    ),
    ReplyLinkTarget.goal => context.push(
      AppRoutes.newGoalFor(
        name: link.goalName ?? '',
        target: link.goalTarget ?? 0,
        months: link.goalMonths,
      ),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final link = reply.link;
    return Container(
      margin: const EdgeInsets.only(top: 12, right: 24),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(reply.text, style: const TextStyle(fontSize: 15, height: 1.45)),
          if (reply.rows.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final row in reply.rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 4,
                  children: [
                    Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: Text(
                            row.label,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: colors.inkSecondary,
                            ),
                          ),
                        ),
                        Text(
                          row.value,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (row.ratio case final ratio?)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 5,
                          backgroundColor: colors.chip,
                          color: colors.primary,
                        ),
                      ),
                  ],
                ),
              ),
          ],
          if (reply.prepared.isNotEmpty) _PreparedCard(reply: reply),
          if (reply.fromTools) ...[
            const SizedBox(height: 8),
            Text(
              l10n.asFootnote,
              style: TextStyle(fontSize: 11.5, color: colors.inkTertiary),
            ),
          ],
          if (link != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _open(context, link),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 44),
                ),
                child: Text(switch (link.target) {
                  ReplyLinkTarget.transactions => l10n.asLinkTransactions,
                  ReplyLinkTarget.budgets => l10n.asLinkBudgets,
                  ReplyLinkTarget.accounts => l10n.asLinkAccounts,
                  ReplyLinkTarget.forecast => l10n.asLinkForecast,
                  ReplyLinkTarget.simulation => l10n.asLinkSimulation,
                  ReplyLinkTarget.goal => l10n.asLinkGoal,
                }),
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Carte « J'ai préparé cette opération » : rien n'est enregistré avant
/// « Enregistrer ».
class _PreparedCard extends ConsumerWidget {
  const _PreparedCard({required this.reply});

  final ReplyEntry reply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final accounts = ref.watch(activeAccountsProvider).value ?? const [];
    final groups = [
      ...?ref.watch(categoryGroupsProvider(CategoryKind.expense)).value,
      ...?ref.watch(categoryGroupsProvider(CategoryKind.income)).value,
    ];
    String categoryName(String? id) =>
        [
          for (final g in groups) ...[g.category, ...g.children],
        ].where((c) => c.id == id).firstOrNull?.name ??
        '—';
    String accountName(String? id) =>
        accounts.where((a) => a.id == id).firstOrNull?.name ?? '—';
    final relative = RelativeDate(
      l10n,
      Localizations.localeOf(context).toLanguageTag(),
      ref.watch(clockProvider)(),
    );
    final ops = reply.prepared;
    final canSave = ops.every((op) => (op.amount?.value ?? 0) > 0);

    Widget row(String label, String value, {bool toCheck = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        spacing: 8,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13.5, color: colors.inkSecondary),
          ),
          if (toCheck)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: colors.warningSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.qeToCheck,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.warning,
                ),
              ),
            ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, op) in ops.indexed) ...[
            if (i > 0) Divider(color: colors.line, height: 16),
            row(
              l10n.asRowAmount,
              op.amount == null
                  ? '—'
                  : '${op.kind == TransactionKind.expense ? MoneyFormat.signed(-op.amount!) : MoneyFormat.amount(op.amount!)} ${l10n.currencyLabel}',
              toCheck: op.uncertain.contains(ParsedField.amount),
            ),
            if (op.kind != TransactionKind.transfer)
              row(
                l10n.asRowCategory,
                categoryName(op.categoryId),
                toCheck: op.uncertain.contains(ParsedField.category),
              ),
            row(
              l10n.asRowAccount,
              op.kind == TransactionKind.transfer
                  ? '${accountName(op.accountId)} → ${accountName(op.toAccountId)}'
                  : accountName(op.accountId),
              toCheck: op.uncertain.contains(ParsedField.account),
            ),
            row(l10n.asRowDate, RelativeDate.capitalize(relative.day(op.date))),
          ],
          const SizedBox(height: 8),
          switch (reply.preparedState) {
            PreparedState.pending => Row(
              spacing: 8,
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: canSave
                        ? () => ref
                              .read(assistantControllerProvider.notifier)
                              .savePrepared(reply)
                        : null,
                    child: Text(l10n.asSavePrepared(ops.length)),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => context.push(
                    AppRoutes.quickEntry(
                      initialText: ops.map((o) => o.source).join(', '),
                    ),
                  ),
                  child: Text(l10n.asEditPrepared),
                ),
              ],
            ),
            PreparedState.saved => const SizedBox.shrink(),
            PreparedState.unsaved => Text(
              l10n.asNotSaved,
              style: TextStyle(fontSize: 13, color: colors.inkTertiary),
            ),
          },
          if (reply.note case final note?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                spacing: 8,
                children: [
                  if (reply.preparedState == PreparedState.saved)
                    Icon(
                      AppIcons.checkCircleBold,
                      size: 16,
                      color: colors.positive,
                    ),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: 13,
                        color: reply.preparedState == PreparedState.saved
                            ? colors.positive
                            : colors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        spacing: 10,
        children: [
          TypingDots(color: colors.inkSecondary),
          Text(
            context.l10n.asTyping,
            style: TextStyle(fontSize: 14, color: colors.inkSecondary),
          ),
        ],
      ),
    );
  }
}

/// Assistant pas chargé (maquette Assistant-SansIA) : les chiffres restent
/// accessibles par des raccourcis.
class _NotLoaded extends ConsumerWidget {
  const _NotLoaded({required this.state});

  final AiModelState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final controller = ref.read(aiModelControllerProvider.notifier);
    final status = state.status;
    final body = switch (status) {
      AiModelStatus.unavailable => l10n.asOffUnavailable,
      AiModelStatus.notInstalled => l10n.asOffNotInstalled,
      AiModelStatus.downloading => l10n.asOffDownloading,
      _ => l10n.asOffBody,
    };
    final shortcuts = [
      (
        AppIcons.chartDonut,
        l10n.navBudgets,
        () => context.go(AppRoutes.budgets),
      ),
      (
        AppIcons.chartLine,
        l10n.navForecast,
        () => context.go(AppRoutes.forecast),
      ),
      (AppIcons.tag, l10n.simTitle, () => context.go(AppRoutes.simulation)),
      (
        AppIcons.microphoneBold,
        l10n.asShortcutDictate,
        () => context.push(AppRoutes.quickEntry()),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.chip,
            ),
            child: Icon(
              AppIcons.chatCircleText,
              size: 28,
              color: colors.inkSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.asOffTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.45,
            color: colors.inkSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (icon, label, onTap) in shortcuts)
              ActionChip(
                avatar: Icon(icon, size: 16),
                label: Text(label),
                onPressed: onTap,
              ),
          ],
        ),
        if (state.notice == AiModelNotice.lowMemory) ...[
          const SizedBox(height: 20),
          Text(
            l10n.aiLowMemory,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: colors.warning),
          ),
        ],
        const SizedBox(height: 24),
        switch (status) {
          AiModelStatus.installed || AiModelStatus.error => FilledButton(
            onPressed: controller.load,
            child: Text(l10n.asLoad),
          ),
          AiModelStatus.notInstalled => FilledButton(
            onPressed: () => context.push(AppRoutes.aiModel),
            child: Text(l10n.asInstall),
          ),
          AiModelStatus.loading => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              ),
              Text(l10n.asLoading),
            ],
          ),
          AiModelStatus.downloading => OutlinedButton(
            onPressed: () => context.push(AppRoutes.aiModel),
            child: Text(l10n.aiModelTitle),
          ),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}
