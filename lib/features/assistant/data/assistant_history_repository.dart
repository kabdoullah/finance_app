import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../quick_entry/domain/quick_entry_parser.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/assistant_reply.dart';

/// Historique de la conversation avec le Copilote, dans la base chiffrée.
class AssistantHistoryRepository {
  AssistantHistoryRepository(this._db, this._clock, {String Function()? newId})
    : _newId = newId ?? const Uuid().v4;

  final AppDatabase _db;
  final Clock _clock;
  final String Function() _newId;

  /// Messages conservés au plus (les plus anciens sont effacés).
  static const maxMessages = 500;

  /// Derniers messages, du plus ancien au plus récent. Une carte qui
  /// attendait encore une confirmation devient « Non enregistrée » : les
  /// chiffres ont pu changer depuis.
  Future<List<ChatEntry>> load() async {
    final rows =
        await (_db.select(_db.assistantMessages)
              ..orderBy([
                (m) => OrderingTerm.desc(m.createdAt),
                (m) => OrderingTerm.desc(m.id),
              ])
              ..limit(maxMessages))
            .get();
    return [
      for (final row in rows.reversed)
        if (row.role == 'user')
          UserEntry(row.body, id: row.id)
        else
          _decodeReply(row),
    ];
  }

  /// Enregistre [entry] et le retourne avec son identifiant.
  Future<T> add<T extends ChatEntry>(T entry) async {
    final id = _newId();
    final now = _clock().toUtc().millisecondsSinceEpoch;
    await _db
        .into(_db.assistantMessages)
        .insert(
          AssistantMessagesCompanion.insert(
            id: id,
            role: entry is UserEntry ? 'user' : 'reply',
            body: switch (entry) {
              UserEntry(:final text) => text,
              ReplyEntry(:final text) => text,
            },
            payload: Value(
              entry is ReplyEntry ? jsonEncode(_encodePayload(entry)) : null,
            ),
            createdAt: now,
          ),
        );
    await _prune();
    return switch (entry) {
      UserEntry(:final text) => UserEntry(text, id: id),
      final ReplyEntry reply => reply.withId(id),
    } as T;
  }

  /// Met à jour une réponse (état de sa carte d'opérations).
  Future<void> update(ReplyEntry entry) async {
    final id = entry.id;
    if (id == null) return;
    await (_db.update(
      _db.assistantMessages,
    )..where((m) => m.id.equals(id))).write(
      AssistantMessagesCompanion(
        payload: Value(jsonEncode(_encodePayload(entry))),
      ),
    );
  }

  /// « Effacer l'historique de conversation ».
  Future<void> clear() => _db.delete(_db.assistantMessages).go();

  Future<void> _prune() => _db.customStatement(
    'DELETE FROM assistant_messages WHERE id NOT IN ('
    'SELECT id FROM assistant_messages '
    'ORDER BY created_at DESC, id DESC LIMIT $maxMessages)',
  );

  // ---------------------------------------------------------------------------
  // JSON.

  static Map<String, Object?> _encodePayload(ReplyEntry e) => {
    'rows': [
      for (final r in e.rows) {'l': r.label, 'v': r.value, 'r': ?r.ratio},
    ],
    'link': ?switch (e.link) {
      null => null,
      final link => {
        't': link.target.name,
        'sl': ?link.simulationLabel,
        'sp': ?link.simulationPrice,
        'gn': ?link.goalName,
        'gt': ?link.goalTarget,
        'gm': ?link.goalMonths,
      },
    },
    'tools': e.fromTools,
    'prepared': [for (final op in e.prepared) _encodeOperation(op)],
    'state': e.preparedState.name,
    'note': ?e.note,
    'head': ?switch (e.head) {
      null => null,
      final h => {'v': h.value, 'c': h.caption, 't': h.tone.name},
    },
  };

  static ReplyEntry _decodeReply(AssistantMessageRow row) {
    final json = row.payload == null
        ? const <String, Object?>{}
        : (jsonDecode(row.payload!) as Map).cast<String, Object?>();
    final link = (json['link'] as Map?)?.cast<String, Object?>();
    final prepared = [
      for (final op in (json['prepared'] as List?) ?? const [])
        _decodeOperation((op as Map).cast<String, Object?>()),
    ];
    final state = PreparedState.values.firstWhere(
      (s) => s.name == json['state'],
      orElse: () => PreparedState.pending,
    );
    return ReplyEntry(
      id: row.id,
      text: row.body,
      rows: [
        for (final r in (json['rows'] as List?) ?? const [])
          ReplyRow(
            (r as Map)['l']! as String,
            r['v']! as String,
            ratio: (r['r'] as num?)?.toDouble(),
          ),
      ],
      link: link == null
          ? null
          : ReplyLink(
              ReplyLinkTarget.values.firstWhere(
                (t) => t.name == link['t'],
                orElse: () => ReplyLinkTarget.transactions,
              ),
              simulationLabel: link['sl'] as String?,
              simulationPrice: link['sp'] as int?,
              goalName: link['gn'] as String?,
              goalTarget: link['gt'] as int?,
              goalMonths: link['gm'] as int?,
            ),
      fromTools: json['tools'] == true,
      prepared: prepared,
      // Une carte en attente d'une autre session n'est plus enregistrable.
      preparedState: state == PreparedState.pending
          ? PreparedState.unsaved
          : state,
      note: json['note'] as String?,
      head: switch ((json['head'] as Map?)?.cast<String, Object?>()) {
        null => null,
        final h => ReplyHead(
          h['v']! as String,
          h['c']! as String,
          tone: ReplyTone.values.firstWhere(
            (t) => t.name == h['t'],
            orElse: () => ReplyTone.neutral,
          ),
        ),
      },
    );
  }

  static Map<String, Object?> _encodeOperation(ParsedOperation op) => {
    'kind': op.kind.storageValue,
    'amount': ?op.amount?.value,
    'category': ?op.categoryId,
    'account': ?op.accountId,
    'to': ?op.toAccountId,
    'date': CalendarDate.format(op.date),
    'description': op.description,
    'source': op.source,
    'uncertain': [for (final f in op.uncertain) f.name],
  };

  static ParsedOperation _decodeOperation(Map<String, Object?> json) =>
      ParsedOperation(
        kind: TransactionKind.fromStorage(json['kind']! as String),
        amount: switch (json['amount']) {
          final int a => Money(a),
          _ => null,
        },
        categoryId: json['category'] as String?,
        accountId: json['account'] as String?,
        toAccountId: json['to'] as String?,
        date: CalendarDate.parse(json['date']! as String),
        description: json['description'] as String? ?? '',
        source: json['source'] as String? ?? '',
        uncertain: {
          for (final name in (json['uncertain'] as List?) ?? const [])
            ...ParsedField.values.where((f) => f.name == name),
        },
      );
}

final assistantHistoryRepositoryProvider = Provider<AssistantHistoryRepository>(
  (ref) => AssistantHistoryRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);
