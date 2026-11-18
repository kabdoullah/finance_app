import 'package:flutter/foundation.dart' show immutable;

import 'number_check.dart';

/// Ligne de chiffres d'une réponse (maquette Assistant) : libellé, valeur
/// déjà formatée, et part de la barre (0 à 1) si elle en a une.
@immutable
class ReplyRow {
  const ReplyRow(this.label, this.value, {this.ratio});

  final String label;
  final String value;
  final double? ratio;
}

/// Écran vers lequel une réponse renvoie.
enum ReplyLinkTarget { transactions, budgets, accounts, forecast, simulation }

@immutable
class ReplyLink {
  const ReplyLink(this.target, {this.simulationLabel, this.simulationPrice});

  final ReplyLinkTarget target;

  /// Achat à pré-remplir dans la simulation.
  final String? simulationLabel;
  final int? simulationPrice;
}

/// Résultat d'un outil, calculé par l'application : [data] part chez Gemma,
/// [rows] et [link] sont affichés tels quels, [summary] remplace la phrase de
/// Gemma si elle contient un nombre absent de [data].
@immutable
class ToolOutcome {
  const ToolOutcome({
    required this.data,
    required this.summary,
    this.rows = const [],
    this.link,
  });

  final Map<String, Object?> data;
  final String summary;
  final List<ReplyRow> rows;
  final ReplyLink? link;
}

/// Message de la conversation.
@immutable
sealed class ChatEntry {
  const ChatEntry();
}

final class UserEntry extends ChatEntry {
  const UserEntry(this.text);

  final String text;
}

final class ReplyEntry extends ChatEntry {
  const ReplyEntry({
    required this.text,
    this.rows = const [],
    this.link,
    this.fromTools = false,
  });

  final String text;
  final List<ReplyRow> rows;
  final ReplyLink? link;

  /// Vrai si des chiffres de l'application sont affichés (mention « Chiffres
  /// calculés par l'application · expliqués par Gemma 4 »).
  final bool fromTools;
}

/// Réponse affichée pour une question, à partir de la phrase de Gemma et des
/// résultats des outils appelés :
/// - avec outils : lignes et lien de l'application ; la phrase de Gemma
///   seulement s'il y a des chiffres à expliquer et que tous ses nombres
///   viennent des outils (ou de la question), sinon le résumé écrit par
///   l'application (plus précis quand l'outil n'a rien à montrer :
///   historique trop court, pas de budget…) ;
/// - sans outil : la phrase de Gemma si elle ne contient aucun nombre, sinon
///   [fallback] (« Je n'ai pas bien compris… »).
ReplyEntry composeReply({
  required String question,
  required String gemmaText,
  required List<ToolOutcome> outcomes,
  required String fallback,
}) {
  final text = gemmaText.replaceAll('**', '').trim();
  if (outcomes.isEmpty) {
    return ReplyEntry(
      text: text.isNotEmpty && NumberCheck.inText(text).isEmpty
          ? text
          : fallback,
    );
  }
  final allowed = {
    ...NumberCheck.inText(question),
    for (final outcome in outcomes) ...NumberCheck.inData(outcome.data),
  };
  final rows = [for (final outcome in outcomes) ...outcome.rows];
  return ReplyEntry(
    text:
        rows.isNotEmpty &&
            text.isNotEmpty &&
            NumberCheck.usesOnly(text, allowed)
        ? text
        : outcomes.map((o) => o.summary).join(' '),
    rows: rows,
    link: outcomes.map((o) => o.link).nonNulls.lastOrNull,
    fromTools: rows.isNotEmpty,
  );
}
