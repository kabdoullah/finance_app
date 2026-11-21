import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../../quick_entry/domain/quick_entry_parser.dart';
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

/// Ton du chiffre clé : neutre, favorable, à surveiller, défavorable.
enum ReplyTone { neutral, positive, warning, negative }

/// Chiffre clé en tête d'une réponse (maquette Assistant : grand chiffre et
/// légende), calculé par l'application.
@immutable
class ReplyHead {
  const ReplyHead(this.value, this.caption, {this.tone = ReplyTone.neutral});

  final String value;
  final String caption;
  final ReplyTone tone;
}

/// Écran vers lequel une réponse renvoie.
enum ReplyLinkTarget {
  transactions,
  budgets,
  accounts,
  forecast,
  simulation,
  goal,
}

@immutable
class ReplyLink {
  const ReplyLink(
    this.target, {
    this.simulationLabel,
    this.simulationPrice,
    this.goalName,
    this.goalTarget,
    this.goalMonths,
  });

  final ReplyLinkTarget target;

  /// Achat à pré-remplir dans la simulation.
  final String? simulationLabel;
  final int? simulationPrice;

  /// Objectif à pré-remplir.
  final String? goalName;
  final int? goalTarget;
  final int? goalMonths;
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
    this.prepared = const [],
    this.head,
  });

  final Map<String, Object?> data;
  final String summary;
  final List<ReplyRow> rows;
  final ReplyLink? link;

  /// Opérations préparées, à confirmer par l'utilisateur.
  final List<ParsedOperation> prepared;

  /// Chiffre clé de la réponse.
  final ReplyHead? head;
}

/// État de la carte d'opérations préparées.
enum PreparedState {
  pending,
  saved,

  /// Pas enregistrée et plus enregistrable (historique d'une autre session).
  unsaved,
}

/// Message de la conversation.
@immutable
sealed class ChatEntry {
  const ChatEntry({this.id});

  /// Identifiant dans l'historique (`null` tant qu'il n'est pas enregistré).
  final String? id;
}

final class UserEntry extends ChatEntry {
  const UserEntry(this.text, {super.id});

  final String text;
}

final class ReplyEntry extends ChatEntry {
  const ReplyEntry({
    required this.text,
    this.rows = const [],
    this.link,
    this.fromTools = false,
    this.prepared = const [],
    this.preparedState = PreparedState.pending,
    this.note,
    this.head,
    super.id,
  });

  final String text;
  final List<ReplyRow> rows;
  final ReplyLink? link;

  /// Opérations préparées (carte Enregistrer / Modifier).
  final List<ParsedOperation> prepared;
  final PreparedState preparedState;

  /// Mention sous la carte (« Dépense enregistrée · solde Wave : … »).
  final String? note;

  /// Chiffre clé (grand chiffre et légende) en tête de la réponse.
  final ReplyHead? head;

  ReplyEntry withPrepared(PreparedState state, {String? note}) => ReplyEntry(
    text: text,
    rows: rows,
    link: link,
    fromTools: fromTools,
    prepared: prepared,
    preparedState: state,
    note: note,
    head: head,
    id: id,
  );

  ReplyEntry withId(String id) => ReplyEntry(
    text: text,
    rows: rows,
    link: link,
    fromTools: fromTools,
    prepared: prepared,
    preparedState: preparedState,
    note: note,
    head: head,
    id: id,
  );

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
  final text = _formatAmounts(gemmaText.replaceAll('**', '').trim());
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
    prepared: [for (final outcome in outcomes) ...outcome.prepared],
    head: outcomes.map((o) => o.head).nonNulls.firstOrNull,
  );
}

/// Montant collé devant sa devise (« 8000 FCFA ») : Gemma ne groupe pas
/// toujours les milliers ; on remet le format du reste de l'application.
final _rawAmount = RegExp(r'(?<![\d.,])(\d{4,})(?=\s?(?:FCFA|F\b|francs))');

String _formatAmounts(String text) => text.replaceAllMapped(
  _rawAmount,
  (m) => MoneyFormat.amount(Money(int.parse(m.group(1)!))),
);
