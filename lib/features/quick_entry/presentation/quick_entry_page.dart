import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
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
import '../../../core/money/amount_input_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../l10n/l10n.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../assistant/data/gemma_entry_assistant.dart';
import '../../assistant/presentation/ai_model_controller.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_providers.dart';
import '../../categories/presentation/category_icons.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_draft.dart';
import '../../transactions/presentation/transaction_labels.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../data/speech_service.dart';
import '../domain/entry_assist.dart';
import '../domain/quick_entry_parser.dart';

enum QuickEntryMode { voice, text }

enum _Stage { listen, input, analyse, recap, done }

/// Bandeau du récapitulatif selon l'aide reçue de Gemma.
enum _AiBanner {
  /// Gemma chargé : rien à signaler.
  none,

  /// Téléphone sans IA possible : analyse simplifiée.
  simplified,

  /// IA possible mais pas chargée : lien vers l'écran du modèle.
  manage,
}

/// Saisie rapide (maquette Saisie-Vocale) : dicter ou écrire une ou
/// plusieurs opérations, vérifier le récapitulatif, enregistrer. Sans IA :
/// l'analyse est faite par [QuickEntryParser].
class QuickEntryPage extends ConsumerStatefulWidget {
  const QuickEntryPage({
    required this.initialMode,
    this.initialText,
    super.key,
  });

  final QuickEntryMode initialMode;

  /// Phrase déjà écrite (« Modifier » d'une opération préparée par le
  /// Copilote) : analysée dès l'ouverture.
  final String? initialText;

  @override
  ConsumerState<QuickEntryPage> createState() => _QuickEntryPageState();
}

/// Problème de dictée affiché à l'écran d'écoute.
enum _VoiceIssue { nothingHeard, missingLanguage, downloading, failed }

class _QuickEntryPageState extends ConsumerState<QuickEntryPage> {
  late QuickEntryMode _mode = widget.initialMode;
  late _Stage _stage = _mode == QuickEntryMode.voice
      ? _Stage.listen
      : _Stage.input;

  // Écoute.
  StreamSubscription<SpeechEvent>? _events;
  bool _listening = false;
  String _transcript = '';
  double _level = 0;

  static bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;
  _VoiceIssue? _issue;
  bool _downloadRequested = false;
  final _stopwatch = Stopwatch();
  Timer? _ticker;

  /// Message affiché en mode texte quand la dictée n'est pas possible.
  String? _textNotice;

  final _text = TextEditingController();

  // Récapitulatif.
  String _source = '';
  final _operations = <_EditableOperation>[];
  bool _saving = false;
  List<Transaction> _saved = const [];
  _AiBanner _banner = _AiBanner.simplified;

  /// Numéro de l'analyse en cours : « Passer » invalide la réponse de Gemma.
  int _analysisRun = 0;

  /// Résultat de l'analyseur, gardé pendant l'étape « Analyse ».
  List<ParsedOperation> _parsed = const [];

  @override
  void initState() {
    super.initState();
    if (_stage == _Stage.listen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
    } else if (widget.initialText case final text?
        when text.trim().isNotEmpty) {
      _text.text = text;
      WidgetsBinding.instance.addPostFrameCallback((_) => _analyse(text));
    }
  }

  @override
  void dispose() {
    _stopListening(cancel: true);
    _text.dispose();
    for (final op in _operations) {
      op.dispose();
    }
    super.dispose();
  }

  SpeechService get _speech => ref.read(speechServiceProvider);

  // ---------------------------------------------------------------------------
  // Dictée.

  Future<void> _listen() async {
    final l10n = context.l10n;
    setState(() {
      _issue = null;
      _transcript = '';
    });
    switch (await _speech.availability()) {
      case SpeechAvailability.unsupported:
        return _toText(notice: l10n.qeUnsupported);
      case SpeechAvailability.missingLanguage:
        return setState(() => _issue = _VoiceIssue.missingLanguage);
      case SpeechAvailability.downloading:
        return setState(() => _issue = _VoiceIssue.downloading);
      case SpeechAvailability.ready || SpeechAvailability.unknown:
        break;
    }
    if (!await _speech.requestPermission()) {
      return _toText(notice: l10n.qeMicDenied);
    }
    if (!mounted || _stage != _Stage.listen) return;
    _events ??= _speech.events.listen(_onSpeech);
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
    setState(() => _listening = true);
    await _speech.start();
  }

  void _onSpeech(SpeechEvent event) {
    if (!mounted) return;
    switch (event) {
      case SpeechStarted():
        break;
      case SpeechLevel(:final value):
        setState(() => _level = ((value + 2) / 12).clamp(0.0, 1.0));
      case SpeechPartial(:final text):
        setState(() => _transcript = text);
      case SpeechFinal(:final text):
        _stopListening();
        final spoken = text.trim().isEmpty ? _transcript : text;
        if (spoken.trim().isEmpty) {
          setState(() => _issue = _VoiceIssue.nothingHeard);
        } else {
          unawaited(_analyse(spoken));
        }
      case SpeechError() when event.isMissingLanguage:
        _stopListening();
        setState(() => _issue = _VoiceIssue.missingLanguage);
      case SpeechError(code: SpeechError.permission):
        _stopListening();
        _toText(notice: context.l10n.qeMicDenied);
      case SpeechError():
        _stopListening();
        setState(
          () => _issue = event.isNothingHeard
              ? _VoiceIssue.nothingHeard
              : _VoiceIssue.failed,
        );
    }
  }

  void _stopListening({bool cancel = false}) {
    _ticker?.cancel();
    _ticker = null;
    _stopwatch.stop();
    if (_listening && cancel) unawaited(_speech.cancel());
    _listening = false;
    _level = 0;
    if (cancel) {
      unawaited(_events?.cancel());
      _events = null;
    }
  }

  void _toText({String? notice}) {
    _stopListening(cancel: true);
    setState(() {
      _mode = QuickEntryMode.text;
      _stage = _Stage.input;
      _textNotice = notice;
    });
  }

  void _toVoice() {
    setState(() {
      _mode = QuickEntryMode.voice;
      _stage = _Stage.listen;
      _textNotice = null;
    });
    unawaited(_listen());
  }

  // ---------------------------------------------------------------------------
  // Analyse et enregistrement.

  Future<void> _analyse(String text) async {
    final accounts = await ref.read(activeAccountsProvider.future);
    final expense = await ref.read(
      categoryGroupsProvider(CategoryKind.expense).future,
    );
    final income = await ref.read(
      categoryGroupsProvider(CategoryKind.income).future,
    );
    final lastUsed = await ref
        .read(transactionsRepositoryProvider)
        .lastUsedAccountId();
    final now = ref.read(clockProvider)();
    final entryContext = QuickEntryContext(
      now: now,
      accounts: accounts,
      expenseGroups: expense,
      incomeGroups: income,
      defaultAccountId:
          lastUsed ?? (accounts.isEmpty ? null : accounts.first.id),
    );
    final parsed = const QuickEntryParser().parse(text, entryContext);
    if (!mounted) return;
    _source = text.trim();
    final ai = ref.read(aiModelControllerProvider);
    final model = ref.read(aiModelControllerProvider.notifier).model;
    if (model == null) {
      _banner = ai.status == AiModelStatus.unavailable
          ? _AiBanner.simplified
          : _AiBanner.manage;
      return _showRecap(parsed);
    }
    _banner = _AiBanner.none;
    if (!parsed.any(EntryAssistPrompt.needsHelp)) return _showRecap(parsed);

    // Gemma complète les champs « À vérifier » (≈ 10 s), sauf si l'utilisateur
    // passe cette étape.
    final run = ++_analysisRun;
    _parsed = parsed;
    setState(() => _stage = _Stage.analyse);
    final completed = await GemmaEntryAssistant(model)
        .complete(parsed, EntryAssistPrompt.build(entryContext));
    if (!mounted || run != _analysisRun || _stage != _Stage.analyse) return;
    _showRecap(completed);
  }

  /// « Passer » : récapitulatif de l'analyseur seul.
  void _skipAnalysis() {
    _analysisRun++;
    _showRecap(_parsed);
  }

  void _showRecap(List<ParsedOperation> parsed) {
    final now = ref.read(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      for (final op in _operations) {
        op.dispose();
      }
      _operations
        ..clear()
        ..addAll([
          for (final p in parsed)
            _EditableOperation.parsed(p, today.difference(p.date).inDays),
        ]);
      _stage = _Stage.recap;
    });
  }

  void _addBlank() {
    final accounts = ref.read(activeAccountsProvider).value ?? const [];
    setState(
      () => _operations.add(
        _EditableOperation.blank(
          accountId:
              _operations.lastOrNull?.accountId ?? accounts.firstOrNull?.id,
        ),
      ),
    );
  }

  List<TransactionDraft> _drafts() {
    final now = ref.read(clockProvider)();
    return [
      for (final op in _operations)
        TransactionDraft(
          kind: op.kind,
          amount: op.amount,
          occurredAt: DateTime(
            now.year,
            now.month,
            now.day - op.daysAgo,
            now.hour,
            now.minute,
            now.second,
          ),
          accountId: op.accountId,
          toAccountId: op.kind == TransactionKind.transfer
              ? op.toAccountId
              : null,
          categoryId: op.kind == TransactionKind.transfer
              ? null
              : op.categoryId,
          description: op.description.text,
        ),
    ];
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ref
        .read(transactionsRepositoryProvider)
        .createAll(
          _drafts(),
          entryMethod: _mode == QuickEntryMode.voice
              ? EntryMethod.voice
              : EntryMethod.text,
        );
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _saving = false;
          _saved = value;
          _stage = _Stage.done;
        });
      case Err():
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.qeSaveFailed)));
    }
  }

  void _restart() {
    setState(() {
      for (final op in _operations) {
        op.dispose();
      }
      _operations.clear();
      _saved = const [];
      _text.clear();
      _source = '';
    });
    _mode == QuickEntryMode.voice ? _toVoice() : _toText();
  }

  void _backToEntry() {
    if (_mode == QuickEntryMode.voice) {
      _toVoice();
    } else {
      setState(() {
        _text.text = _source;
        _stage = _Stage.input;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Écrans.

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Garde les listes chargées pour l'analyse et le récapitulatif.
    final accounts = ref.watch(activeAccountsProvider).value ?? const [];
    ref
      ..watch(categoryGroupsProvider(CategoryKind.expense))
      ..watch(categoryGroupsProvider(CategoryKind.income));

    final heading = switch (_stage) {
      _Stage.listen => l10n.qeDictate,
      _Stage.input => l10n.qeWrite,
      _Stage.analyse => l10n.qeAnalyseHeading,
      _Stage.recap => l10n.qeRecapHeading,
      _Stage.done => l10n.qeDoneHeading,
    };
    final canSwitch = _stage == _Stage.listen || _stage == _Stage.input;
    return PopScope(
      canPop: _stage != _Stage.recap,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToEntry();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(heading),
          leading: _stage == _Stage.recap
              ? IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: _backToEntry,
                  icon: const Icon(AppIcons.caretLeftBold, size: 20),
                )
              : IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => context.pop(),
                  icon: const Icon(AppIcons.xBold, size: 18),
                ),
          actions: [
            if (canSwitch)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: _mode == QuickEntryMode.voice
                      ? () => _toText()
                      : _toVoice,
                  icon: Icon(
                    _mode == QuickEntryMode.voice
                        ? AppIcons.keyboard
                        : AppIcons.microphoneBold,
                    size: 18,
                  ),
                  label: Text(
                    _mode == QuickEntryMode.voice
                        ? l10n.qeWrite
                        : l10n.qeDictate,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: switch (_stage) {
            _Stage.listen => _listenStage(context),
            _Stage.input => _inputStage(context),
            _Stage.analyse => _analyseStage(context),
            _Stage.recap => _recapStage(context, accounts),
            _Stage.done => _doneStage(context),
          },
        ),
      ),
    );
  }

  Widget _listenStage(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    if (_issue case _VoiceIssue.missingLanguage || _VoiceIssue.downloading) {
      return _languageGuide(context);
    }
    final seconds = _stopwatch.elapsed.inSeconds;
    final timer =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    final message = switch (_issue) {
      _VoiceIssue.nothingHeard => l10n.qeNothingHeard,
      _VoiceIssue.failed => l10n.errorGeneric,
      _ => null,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_listening)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.negative,
                  ),
                ),
                Flexible(
                  child: Text(
                    l10n.qeListening,
                    style: TextStyle(fontSize: 13, color: colors.inkSecondary),
                  ),
                ),
              ],
            ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  _transcript.isNotEmpty
                      ? '« $_transcript »'
                      : message ?? l10n.qeListenHint,
                  textAlign: TextAlign.center,
                  style: _transcript.isNotEmpty
                      ? const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        )
                      : TextStyle(
                          fontSize: message != null ? 17 : 15,
                          color: message != null
                              ? colors.ink
                              : colors.inkSecondary,
                          height: 1.45,
                        ),
                ),
              ),
            ),
          ),
          if (_listening)
            Text(
              timer,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colors.inkSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          const SizedBox(height: 16),
          Center(
            child: Semantics(
              button: true,
              label: _listening ? l10n.qeTapToFinish : l10n.qeTapToRetry,
              child: GestureDetector(
                onTap: _listening ? () => _speech.stop() : _listen,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary,
                    boxShadow: [
                      if (_listening)
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.25),
                          spreadRadius: 6 + 18 * _level,
                        ),
                    ],
                  ),
                  child: Icon(
                    _listening ? AppIcons.stop : AppIcons.microphoneBold,
                    size: 34,
                    color: colors.surface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ExcludeSemantics(
            child: Text(
              _listening ? l10n.qeTapToFinish : l10n.qeTapToRetry,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.inkSecondary),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  /// Guide d'installation du français hors connexion.
  Widget _languageGuide(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final downloading = _issue == _VoiceIssue.downloading;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Text(
          l10n.qeLangTitle,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          downloading ? l10n.qeLangDownloading : l10n.qeLangBody,
          style: TextStyle(
            fontSize: 15,
            color: colors.inkSecondary,
            height: 1.45,
          ),
        ),
        // iOS ne laisse pas une application installer une langue : les
        // étapes sont montrées d'emblée.
        if (_isIos || _downloadRequested || downloading) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.chip,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _isIos ? l10n.qeLangManualIos : l10n.qeLangManual,
              style: const TextStyle(fontSize: 14, height: 1.45),
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (!_isIos && !downloading && !_downloadRequested)
          FilledButton(
            onPressed: () async {
              await _speech.requestFrenchDownload();
              if (mounted) setState(() => _downloadRequested = true);
            },
            child: Text(l10n.qeLangInstall),
          )
        else
          FilledButton(onPressed: _listen, child: Text(l10n.qeLangCheck)),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _toText(),
          style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
          child: Text(l10n.qeWriteInstead),
        ),
      ],
    );
  }

  Widget _inputStage(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final examples = [l10n.qeExample1, l10n.qeExample2, l10n.qeExample3];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            children: [
              if (_textNotice case final notice?) ...[
                _Notice(text: notice),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _text,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 18, height: 1.4),
                decoration: InputDecoration(hintText: l10n.qeInputPrompt),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.qeExamples,
                style: TextStyle(fontSize: 13, color: colors.inkSecondary),
              ),
              const SizedBox(height: 4),
              for (final example in examples)
                InkWell(
                  onTap: () => setState(() {
                    _text.text = example;
                    _text.selection = TextSelection.collapsed(
                      offset: example.length,
                    );
                  }),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '« $example »',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: FilledButton(
            onPressed: _text.text.trim().isEmpty
                ? null
                : () => _analyse(_text.text),
            child: Text(l10n.qeAnalyse),
          ),
        ),
      ],
    );
  }

  /// Étape « Analyse » de la maquette : Gemma complète les champs
  /// incertains.
  Widget _analyseStage(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    Widget step(Widget leading, String label, {bool done = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        spacing: 14,
        children: [
          SizedBox(width: 24, height: 24, child: Center(child: leading)),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: done ? colors.inkSecondary : colors.ink,
                fontWeight: done ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '« $_source »',
            style: TextStyle(
              fontSize: 15,
              color: colors.inkSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          step(
            Icon(AppIcons.checkBold, size: 18, color: colors.positive),
            _mode == QuickEntryMode.voice ? l10n.qeStepVoice : l10n.qeStepText,
            done: true,
          ),
          step(
            SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colors.primary,
              ),
            ),
            l10n.qeStepGemma,
          ),
          const Spacer(),
          TextButton(
            onPressed: _skipAnalysis,
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(l10n.qeSkip),
          ),
        ],
      ),
    );
  }

  Widget _recapStage(BuildContext context, List<Account> accounts) {
    final colors = context.colors;
    final l10n = context.l10n;
    final drafts = _drafts();
    final valid =
        drafts.isNotEmpty && drafts.every((d) => d.validate().isEmpty);
    Money total(TransactionKind kind) => Money(
      drafts
          .where((d) => d.kind == kind)
          .fold(0, (sum, d) => sum + d.amount.value),
    );
    final out = total(TransactionKind.expense);
    final inn = total(TransactionKind.income);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            children: [
              if (_source.isNotEmpty)
                Text(
                  '« $_source »',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.inkSecondary,
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 14),
              switch (_banner) {
                _AiBanner.none => const SizedBox.shrink(),
                _AiBanner.simplified => _Notice(text: l10n.qeSimplified),
                _AiBanner.manage => _Notice(
                  text: '${l10n.qeAiUnavailable} ${l10n.qeSimplified}',
                  action: l10n.qeManageAi,
                  onAction: () => context.push(AppRoutes.aiModel),
                ),
              },
              const SizedBox(height: 18),
              Text(
                l10n.qeCount(_operations.length),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_operations.isEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.qeNoOperation,
                  style: TextStyle(fontSize: 14, color: colors.inkSecondary),
                ),
              ],
              for (final (i, op) in _operations.indexed) ...[
                const SizedBox(height: 12),
                _OperationCard(
                  key: ObjectKey(op),
                  operation: op,
                  accounts: accounts,
                  onChanged: () => setState(() {}),
                  onRemove: () => setState(() {
                    _operations.removeAt(i).dispose();
                  }),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addBlank,
                icon: const Icon(AppIcons.plusBold, size: 16),
                label: Text(l10n.qeAddOperation),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.line)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              if (out.value > 0 || inn.value > 0)
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.qeTotal,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.inkSecondary,
                        ),
                      ),
                    ),
                    if (out.value > 0)
                      Text(
                        '${MoneyFormat.signed(-out)} ${l10n.currencyLabel}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (inn.value > 0)
                      Text(
                        '${MoneyFormat.signed(inn)} ${l10n.currencyLabel}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.positive,
                        ),
                      ),
                  ],
                ),
              FilledButton(
                onPressed: valid && !_saving ? _save : null,
                child: Text(l10n.qeSave(_operations.length)),
              ),
              Text(
                l10n.qeNothingSaved,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colors.inkTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _doneStage(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primarySoft,
                  ),
                  child: Icon(
                    AppIcons.checkBold,
                    size: 28,
                    color: colors.onPrimarySoft,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.qeDoneTitle(_saved.length),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.qeDoneSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.inkSecondary),
              ),
              const SizedBox(height: 20),
              for (final transaction in _saved)
                TransactionTile(transaction: transaction),
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
                onPressed: () => context.go(AppRoutes.transactions),
                child: Text(l10n.qeSeeTransactions),
              ),
              TextButton(
                onPressed: _restart,
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                child: Text(
                  _mode == QuickEntryMode.voice
                      ? l10n.qeDictateAnother
                      : l10n.qeWriteAnother,
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                child: Text(l10n.txBackHome),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Opération du récapitulatif, modifiable avant l'enregistrement.
class _EditableOperation {
  _EditableOperation({
    required this.kind,
    required this.categoryId,
    required this.accountId,
    required this.toAccountId,
    required this.daysAgo,
    required this.uncertain,
    Money? amount,
    String description = '',
  }) : amountText = TextEditingController(
         text: amount == null ? '' : MoneyFormat.amount(amount),
       ),
       description = TextEditingController(text: description);

  factory _EditableOperation.parsed(ParsedOperation op, int daysAgo) =>
      _EditableOperation(
        kind: op.kind,
        amount: op.amount,
        categoryId: op.categoryId,
        accountId: op.accountId,
        toAccountId: op.toAccountId,
        daysAgo: daysAgo.clamp(0, 2),
        uncertain: {...op.uncertain},
        description: op.description,
      );

  factory _EditableOperation.blank({String? accountId}) => _EditableOperation(
    kind: TransactionKind.expense,
    categoryId: CategoryKind.expense.fallbackId,
    accountId: accountId,
    toAccountId: null,
    daysAgo: 0,
    uncertain: {ParsedField.category},
  );

  TransactionKind kind;
  String? categoryId;
  String? accountId;
  String? toAccountId;
  int daysAgo;
  final Set<ParsedField> uncertain;
  final TextEditingController amountText;
  final TextEditingController description;

  Money get amount => AmountInputFormatter.parse(amountText.text);

  void dispose() {
    amountText.dispose();
    description.dispose();
  }
}

class _OperationCard extends ConsumerWidget {
  const _OperationCard({
    required this.operation,
    required this.accounts,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final _EditableOperation operation;
  final List<Account> accounts;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  void _update(void Function(_EditableOperation op) change) {
    change(operation);
    onChanged();
  }

  String? _nextAccount(String? current, {String? skip}) {
    final ids = [
      for (final a in accounts)
        if (a.id != skip) a.id,
    ];
    if (ids.isEmpty) return null;
    final index = ids.indexOf(current ?? '');
    return ids[(index + 1) % ids.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final op = operation;
    final isTransfer = op.kind == TransactionKind.transfer;
    final isIncome = op.kind == TransactionKind.income;
    final groups = isTransfer
        ? const <CategoryGroup>[]
        : ref.watch(categoryGroupsProvider(op.kind.categoryKind!)).value ??
              const <CategoryGroup>[];
    // Catégorie principale de la catégorie (ou sous-catégorie) retenue.
    final mainId = groups
        .where(
          (g) =>
              g.category.id == op.categoryId ||
              g.children.any((c) => c.id == op.categoryId),
        )
        .firstOrNull
        ?.category
        .id;
    String accountName(String? id) =>
        accounts.where((a) => a.id == id).firstOrNull?.name ?? '—';

    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = ref.watch(clockProvider)();
    final date = DateTime(now.year, now.month, now.day - op.daysAgo);
    final dayLabel = switch (op.daysAgo) {
      0 => l10n.today,
      1 => l10n.yesterday,
      _ => l10n.qeDayBeforeYesterday,
    };
    final kindForeground = isIncome ? colors.onPrimarySoft : colors.ink;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Material(
                color: isIncome ? colors.primarySoft : colors.chip,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => _update((op) {
                    op.kind =
                        TransactionKind.values[(op.kind.index + 1) %
                            TransactionKind.values.length];
                    op.categoryId = op.kind.categoryKind?.fallbackId;
                    if (op.kind == TransactionKind.transfer) {
                      op.toAccountId ??= _nextAccount(null, skip: op.accountId);
                    } else {
                      op.uncertain.add(ParsedField.category);
                    }
                  }),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        Icon(op.kind.icon, size: 14, color: kindForeground),
                        Text(
                          op.kind.label(l10n),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kindForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: l10n.qeRemove,
                onPressed: onRemove,
                icon: Icon(AppIcons.xBold, size: 16, color: colors.inkTertiary),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: op.amountText,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [AmountInputFormatter(maxDigits: 9)],
                  onChanged: (_) =>
                      _update((op) => op.uncertain.remove(ParsedField.amount)),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.6,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.qeAmount,
                    suffixText: l10n.currencyLabel,
                    helperText: op.uncertain.contains(ParsedField.amount)
                        ? l10n.qeToCheck
                        : null,
                    helperStyle: TextStyle(color: colors.warning),
                  ),
                ),
                TextField(
                  controller: op.description,
                  maxLength: TransactionDraft.maxDescriptionLength,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    labelText: l10n.qeDescription,
                    counterText: '',
                  ),
                ),
                if (!isTransfer) ...[
                  const SizedBox(height: 12),
                  if (op.uncertain.contains(ParsedField.category))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _ToCheck(label: l10n.qeToCheck),
                    ),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final group in groups)
                          if (!group.category.isHidden ||
                              group.category.id == mainId)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoicePill(
                                label: group.category.name,
                                icon: categoryIcon(group.category.iconKey),
                                height: 40,
                                selected: group.category.id == mainId,
                                onTap: () => _update((op) {
                                  // Garde la sous-catégorie déjà reconnue
                                  // dans ce groupe.
                                  if (group.category.id != mainId) {
                                    op.categoryId = group.category.id;
                                  }
                                  op.uncertain.remove(ParsedField.category);
                                }),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                _FieldRow(
                  label: isTransfer ? l10n.qeFrom : l10n.qeAccount,
                  value: accountName(op.accountId),
                  toCheck: op.uncertain.contains(ParsedField.account)
                      ? l10n.qeToCheck
                      : null,
                  onTap: () => _update((op) {
                    op.accountId = _nextAccount(op.accountId);
                    op.uncertain.remove(ParsedField.account);
                  }),
                ),
                if (isTransfer)
                  _FieldRow(
                    label: l10n.qeTo,
                    value: accountName(op.toAccountId),
                    onTap: () => _update(
                      (op) => op.toAccountId = _nextAccount(
                        op.toAccountId,
                        skip: op.accountId,
                      ),
                    ),
                  ),
                _FieldRow(
                  label: l10n.qeDate,
                  value:
                      '${RelativeDate.capitalize(dayLabel)}, '
                      '${AppDateFormat.dayMonth(date, locale)}',
                  showDivider: false,
                  onTap: () =>
                      _update((op) => op.daysAgo = (op.daysAgo + 1) % 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne « libellé · valeur » qui passe à la valeur suivante au toucher.
class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.toCheck,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final String? toCheck;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: showDivider
            ? BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.line)),
              )
            : null,
        child: Row(
          spacing: 8,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14, color: colors.inkSecondary),
            ),
            if (toCheck case final text?) _ToCheck(label: text),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(AppIcons.caretRight, size: 14, color: colors.inkTertiary),
          ],
        ),
      ),
    );
  }
}

class _ToCheck extends StatelessWidget {
  const _ToCheck({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: colors.warningSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colors.warning,
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.chip,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Icon(AppIcons.info, size: 18, color: colors.inkSecondary),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: colors.inkSecondary,
                    height: 1.4,
                  ),
                ),
                if (action case final label?)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 40),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
