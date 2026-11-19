// Les contraintes CHECK de drift référencent la colonne dans sa propre
// définition : faux positif connu de ce lint.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

/// Historique de la conversation avec le Copilote (base chiffrée, comme le
/// reste). Effaçable depuis les Paramètres ; limité aux derniers messages.
@DataClassName('AssistantMessageRow')
@TableIndex(name: 'assistant_messages_created', columns: {#createdAt})
class AssistantMessages extends Table {
  TextColumn get id => text()();

  /// `user` (question) ou `reply` (réponse du Copilote).
  TextColumn get role => text().check(role.isIn(const ['user', 'reply']))();

  TextColumn get body => text()();

  /// Réponse : lignes de chiffres, lien, opérations préparées et leur état
  /// (JSON). `NULL` pour une question.
  TextColumn get payload => text().nullable()();

  /// Epoch ms UTC.
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
