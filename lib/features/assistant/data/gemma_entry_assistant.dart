import 'dart:async';

import 'package:flutter_edge_ai/flutter_edge_ai.dart';

import '../../../core/errors/error_reporter.dart';
import '../../quick_entry/domain/entry_assist.dart';
import '../../quick_entry/domain/quick_entry_parser.dart';

/// Demande à Gemma (déjà chargé) de compléter les opérations incertaines
/// d'une saisie rapide, une par une, dans une même conversation vidée entre
/// deux opérations. En cas d'erreur ou de délai dépassé, l'opération reste
/// celle de l'analyseur.
class GemmaEntryAssistant {
  const GemmaEntryAssistant(this._model);

  final InferenceModel _model;

  static const _timeout = Duration(seconds: 30);

  Future<List<ParsedOperation>> complete(
    List<ParsedOperation> operations,
    EntryAssistPrompt prompt,
  ) async {
    if (!operations.any(EntryAssistPrompt.needsHelp)) return operations;
    final InferenceChat chat;
    try {
      chat = await _model.openChat(
        temperature: 0,
        systemInstruction: prompt.instruction,
        responseFormat: ResponseFormat.jsonSchema(prompt.schema),
      );
    } on Object catch (error, stack) {
      reportError(error, stack);
      return operations;
    }
    try {
      final completed = <ParsedOperation>[];
      for (final op in operations) {
        if (!EntryAssistPrompt.needsHelp(op) || op.source.isEmpty) {
          completed.add(op);
          continue;
        }
        try {
          await chat.addQueryChunk(Message.text(text: op.source, isUser: true));
          final response = await chat.generateChatResponse().timeout(_timeout);
          completed.add(
            response is TextResponse ? prompt.merge(op, response.token) : op,
          );
        } on Object catch (error, stack) {
          reportError(error, stack);
          completed.add(op);
        } finally {
          await chat.clearHistory();
        }
      }
      return completed;
    } finally {
      await chat.close();
    }
  }
}
