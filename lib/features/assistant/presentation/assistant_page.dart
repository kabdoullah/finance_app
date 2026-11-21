import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/clock.dart';
import '../../../core/formatting/relative_date.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/section_tint.dart';
import '../../../l10n/l10n.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_providers.dart';
import '../../quick_entry/domain/quick_entry_parser.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/assistant_reply.dart';
import 'ai_model_controller.dart';
import 'assistant_controller.dart';
import 'week_card.dart';

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
    return SectionTint(
      color: context.colors.infoTint,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          toolbarHeight: 72,
          titleSpacing: 24,
          shape: Border(bottom: BorderSide(color: colors.line)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(l10n.asTitle, style: AppText.screenTitle),
              Row(
                spacing: 5,
                children: [
                  Icon(
                    AppIcons.lockSimple,
                    size: 12,
                    color: colors.inkSecondary,
                  ),
                  Flexible(
                    child: Text(
                      l10n.asSubtitle,
                      style: AppText.caption.copyWith(
                        color: colors.inkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: l10n.asSettings,
              onPressed: () => context.push(AppRoutes.aiModel),
              icon: const Icon(AppIcons.gearSix, size: 20),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ai.status == AiModelStatus.ready
            ? const _Conversation()
            : _NotLoaded(state: ai),
      ),
    );
  }
}

/// Questions proposées en pastilles.
List<(IconData, String)> _suggestions(AppLocalizations l10n) => [
  (AppIcons.wallet, l10n.asSuggest3),
  (AppIcons.chartDonut, l10n.asSuggest2),
  (AppIcons.trendDown, l10n.asSuggestSave),
  (AppIcons.piggyBank, l10n.asSuggestGoal),
  (AppIcons.handCoins, l10n.asSuggest5),
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              if (state.entries.isEmpty) const WeekCard(),
              for (final (i, entry) in state.entries.indexed)
                if (i < _initialEntries)
                  _entry(entry)
                else
                  FadeSlideIn(key: ValueKey(i), child: _entry(entry)),
              if (state.busy) const _Typing(),
            ],
          ),
        ),
        _Composer(
          controller: _input,
          enabled: true,
          busy: state.busy,
          onSend: _send,
        ),
      ],
    );
  }
}

/// Question posée (maquette) : bulle claire à guillemets, chaque échange
/// séparé par un filet.
class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.line)),
      ),
      alignment: Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: 0.86,
        alignment: Alignment.centerRight,
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.line),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
                bottomLeft: Radius.circular(AppRadius.lg),
                bottomRight: Radius.circular(AppRadius.xs),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    AppIcons.quotesFill,
                    size: 16,
                    color: colors.inkTertiary,
                  ),
                ),
                Flexible(
                  child: Text(text, style: AppText.bodyLarge.semibold.prose),
                ),
              ],
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ReplyLabel(),
          if (reply.head case final head?) _ReplyHead(head: head),
          const SizedBox(height: 10),
          Text(reply.text, style: AppText.bodyLarge.prose),
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
                            style: AppText.bodySmall.copyWith(
                              color: colors.inkSecondary,
                            ),
                          ),
                        ),
                        Text(row.value, style: AppText.bodySmall.semibold),
                      ],
                    ),
                    if (row.ratio case final ratio?)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
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
            const SizedBox(height: 10),
            Row(
              spacing: 5,
              children: [
                Icon(AppIcons.info, size: 13, color: colors.inkTertiary),
                Expanded(
                  child: Text(
                    l10n.asFootnote,
                    style: AppText.tag.copyWith(color: colors.inkTertiary),
                  ),
                ),
              ],
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    Flexible(
                      child: Text(switch (link.target) {
                        ReplyLinkTarget.transactions => l10n.asLinkTransactions,
                        ReplyLinkTarget.budgets => l10n.asLinkBudgets,
                        ReplyLinkTarget.accounts => l10n.asLinkAccounts,
                        ReplyLinkTarget.forecast => l10n.asLinkForecast,
                        ReplyLinkTarget.simulation => l10n.asLinkSimulation,
                        ReplyLinkTarget.goal => l10n.asLinkGoal,
                      }),
                    ),
                    const Icon(AppIcons.arrowRightBold, size: 12),
                  ],
                ),
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
            style: AppText.bodySmall.copyWith(color: colors.inkSecondary),
          ),
          if (toCheck)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: colors.warningSoft,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                l10n.qeToCheck,
                style: AppText.tag.copyWith(color: colors.warning),
              ),
            ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppText.bodySmall.semibold,
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
        borderRadius: BorderRadius.circular(AppRadius.field),
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
              style: AppText.label.copyWith(color: colors.inkTertiary),
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
                      style: AppText.label.copyWith(
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

/// « Gemma 4 · je calcule… » et l'esquisse de la réponse.
class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    Widget bar(double width, double height) => FractionallySizedBox(
      widthFactor: width,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colors.chip,
          borderRadius: BorderRadius.circular(height / 3),
        ),
      ),
    );
    return Semantics(
      liveRegion: true,
      label: '${l10n.asTypingModel} · ${l10n.asTyping}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Row(
              spacing: 8,
              children: [
                TypingDots(color: colors.info),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l10n.asTypingModel,
                          style: TextStyle(
                            color: colors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: ' · ${l10n.asTyping}'),
                      ],
                    ),
                    style: AppText.label.copyWith(color: colors.inkSecondary),
                  ),
                ),
              ],
            ),
            bar(0.46, 26),
            bar(0.88, 12),
            bar(0.70, 12),
          ],
        ),
      ),
    );
  }
}

/// Chiffre clé de la réponse (maquette : 28 px gras et sa légende).
class _ReplyHead extends StatelessWidget {
  const _ReplyHead({required this.head});

  final ReplyHead head;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(
            head.value,
            style: AppText.amount(28).bold.copyWith(
              height: 1.15,
              color: switch (head.tone) {
                ReplyTone.neutral => colors.ink,
                ReplyTone.positive => colors.positive,
                ReplyTone.warning => colors.warning,
                ReplyTone.negative => colors.negative,
              },
            ),
          ),
          Text(
            head.caption,
            style: AppText.bodySmall.copyWith(color: colors.inkSecondary),
          ),
        ],
      ),
    );
  }
}

/// « ✦ COPILOTE » au-dessus de chaque réponse.
class _ReplyLabel extends StatelessWidget {
  const _ReplyLabel();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      spacing: 6,
      children: [
        Icon(AppIcons.sparkleFill, size: 14, color: colors.info),
        Text(
          context.l10n.asReplyLabel.toUpperCase(),
          style: AppText.overline.bold.copyWith(color: colors.info),
        ),
      ],
    );
  }
}

/// Bas de l'écran (maquette) : questions proposées, champ en pilule avec la
/// dictée, bouton Envoyer. Désactivé tant que l'assistant n'est pas chargé.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.enabled,
    required this.busy,
    this.controller,
    this.onSend,
  });

  final TextEditingController? controller;
  final bool enabled;
  final bool busy;
  final void Function([String?])? onSend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final active = enabled && !busy;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Column(
            spacing: 10,
            children: [
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final (icon, label) in _suggestions(l10n))
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Opacity(
                          opacity: active ? 1 : 0.5,
                          child: Material(
                            color: colors.surface,
                            shape: StadiumBorder(
                              side: BorderSide(color: colors.line),
                            ),
                            child: InkWell(
                              customBorder: const StadiumBorder(),
                              onTap: active ? () => onSend?.call(label) : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Row(
                                  spacing: 6,
                                  children: [
                                    Icon(icon, size: 15, color: colors.info),
                                    Text(label, style: AppText.label.semibold),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 52),
                        padding: const EdgeInsets.only(left: 16, right: 4),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          border: Border.all(color: colors.line),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                enabled: active,
                                minLines: 1,
                                maxLines: 4,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => onSend?.call(),
                                style: AppText.bodyLarge,
                                decoration: InputDecoration(
                                  hintText: l10n.asInputHint,
                                  hintMaxLines: 1,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  filled: false,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.asShortcutDictate,
                              onPressed: () =>
                                  context.push(AppRoutes.quickEntry()),
                              icon: Icon(
                                AppIcons.microphoneFill,
                                size: 20,
                                color: colors.info,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox.square(
                      dimension: 52,
                      child: IconButton.filled(
                        tooltip: l10n.asSend,
                        onPressed: active ? () => onSend?.call() : null,
                        icon: const Icon(AppIcons.arrowUpBold, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              // Chiffres calculés par l'application, même sans IA (maquette).
              const WeekCard(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.infoSoft,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            AppIcons.cpuBold,
                            size: 18,
                            color: colors.info,
                          ),
                        ),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${l10n.asOffTitle} ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(text: body),
                              ],
                            ),
                            style: AppText.body.prose,
                          ),
                        ),
                      ],
                    ),
                    if (state.notice == AiModelNotice.lowMemory) ...[
                      const SizedBox(height: 20),
                      Text(
                        l10n.aiLowMemory,
                        textAlign: TextAlign.center,
                        style: AppText.body.copyWith(color: colors.warning),
                      ),
                    ],
                    switch (status) {
                      AiModelStatus.installed ||
                      AiModelStatus.error => FilledButton(
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
                ),
              ),
            ],
          ),
        ),
        const _Composer(enabled: false, busy: false),
      ],
    );
  }
}
