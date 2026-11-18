import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_reporter.dart';
import '../../../l10n/l10n.dart';
import '../data/assistant_toolbox.dart';
import '../domain/assistant_reply.dart';
import 'ai_model_controller.dart';

@immutable
class AssistantState {
  const AssistantState({this.entries = const [], this.busy = false});

  final List<ChatEntry> entries;

  /// Vrai pendant qu'une réponse est préparée (« Analyse de tes
  /// opérations… »).
  final bool busy;
}

/// Conversation avec le Copilote. Une conversation Gemma reste ouverte tant
/// que le modèle est chargé (≈ 4 s par question dès la 2e), et est vidée
/// après quelques questions pour rester dans la mémoire du modèle.
class AssistantController extends Notifier<AssistantState> {
  InferenceChat? _chat;
  InferenceModel? _chatModel;
  AssistantToolbox? _toolbox;
  int _turns = 0;

  /// Questions avant de repartir d'une conversation vide.
  static const maxTurns = 6;
  static const _timeout = Duration(seconds: 90);

  final AppLocalizations _l10n = lookupAppLocalizations(const Locale('fr'));

  @override
  AssistantState build() {
    ref
      ..listen(aiModelControllerProvider, (_, next) {
        if (next.status != AiModelStatus.ready) unawaited(_closeChat());
      })
      ..onDispose(() => unawaited(_closeChat()));
    return const AssistantState();
  }

  Future<void> ask(String question) async {
    final text = question.trim();
    if (text.isEmpty || state.busy) return;
    final model = ref.read(aiModelControllerProvider.notifier).model;
    if (model == null) return;

    state = AssistantState(
      entries: [...state.entries, UserEntry(text)],
      busy: true,
    );
    ReplyEntry reply;
    try {
      reply = await _answer(model, text).timeout(_timeout);
    } on Object catch (error, stack) {
      reportError(error, stack);
      await _closeChat();
      reply = ReplyEntry(text: _l10n.asError);
    }
    state = AssistantState(entries: [...state.entries, reply]);
  }

  Future<ReplyEntry> _answer(InferenceModel model, String question) async {
    final chat = await _openChat(model);
    final toolbox = _toolbox!;
    _turns++;
    await chat.addQueryChunk(Message.text(text: question, isUser: true));
    final outcomes = <ToolOutcome>[];
    final text = StringBuffer();
    await for (final response in chat.generateChatResponseWithTools(
      onToolCall: (call) async {
        final outcome = await toolbox.run(call.name, call.args);
        outcomes.add(outcome);
        return outcome.data;
      },
      maxToolTurns: 2,
    )) {
      if (response is TextResponse) text.write(response.token);
    }
    return composeReply(
      question: question,
      gemmaText: text.toString(),
      outcomes: outcomes,
      fallback: _l10n.asFallback,
    );
  }

  Future<InferenceChat> _openChat(InferenceModel model) async {
    final current = _chat;
    if (current != null && _chatModel == model && _turns < maxTurns) {
      return current;
    }
    await _closeChat();
    // Outils reconstruits à chaque conversation : catégories et comptes à
    // jour.
    final toolbox = _toolbox = AssistantToolbox(ref, _l10n);
    final tools = await toolbox.prepare();
    final chat = await model.openChat(
      temperature: 0,
      tools: tools,
      supportsFunctionCalls: true,
      systemInstruction: AssistantToolbox.instruction,
    );
    _chat = chat;
    _chatModel = model;
    _turns = 0;
    return chat;
  }

  Future<void> _closeChat() async {
    final chat = _chat;
    _chat = null;
    _chatModel = null;
    _turns = 0;
    try {
      await chat?.close();
    } on Object catch (error, stack) {
      reportError(error, stack);
    }
  }
}

final assistantControllerProvider =
    NotifierProvider<AssistantController, AssistantState>(
      AssistantController.new,
    );
