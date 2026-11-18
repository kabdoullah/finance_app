import 'dart:convert';

import '../../../core/formatting/text_search.dart';
import '../../../core/money/money.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction.dart';
import 'quick_entry_parser.dart';

/// Consigne et schéma JSON envoyés à Gemma pour compléter une opération de
/// saisie rapide, construits à partir des catégories et comptes de
/// l'utilisateur (codes stables sans espace ni accent : le décodage contraint
/// plante sinon, voir tools/ai_poc/RAPPORT.md).
///
/// Gemma ne calcule rien et n'enregistre rien : sa réponse ne remplit que les
/// champs « À vérifier » de l'analyseur ([merge]), qui le restent.
class EntryAssistPrompt {
  EntryAssistPrompt._({
    required this.instruction,
    required this.schema,
    required this.categories,
    required this.accounts,
  });

  factory EntryAssistPrompt.build(QuickEntryContext context) {
    final categories = <String, Category>{};
    final categoryLines = <String>[];
    for (final (label, groups) in [
      ('dépenses', context.expenseGroups),
      ('revenus', context.incomeGroups),
    ]) {
      final items = <String>[];
      for (final group in groups) {
        if (group.category.isHidden) continue;
        final code = stableCode(group.category.name, categories.keys);
        categories[code] = group.category;
        final children = [for (final c in group.visibleChildren) c.name];
        items.add(children.isEmpty ? code : '$code (${children.join(', ')})');
      }
      categoryLines.add('($label) ${items.join(', ')}');
    }
    final accounts = <String, String>{};
    for (final account in context.accounts) {
      accounts[stableCode(account.name, accounts.keys)] = account.id;
    }

    final instruction =
        "Tu analyses une saisie rapide d'opération en FCFA (Côte d'Ivoire) "
        'et tu renvoies uniquement le JSON demandé.\n'
        'kind : expense pour un achat ou un paiement ; income pour de '
        "l'argent reçu (salaire, vente, argent envoyé par quelqu'un) ; "
        'transfer UNIQUEMENT si la personne déplace de l\'argent entre deux '
        'de ses comptes (« de X vers Y »).\n'
        'amount : entier en FCFA (« mille » = ×1000, « 75 000 » = 75000), '
        '0 si aucun montant.\n'
        'category : ${categoryLines.join(' ; ')} ; none pour un transfert '
        'ou si rien ne correspond.\n'
        'account : ${accounts.keys.join(', ')} ; none si aucun compte '
        "n'est cité ; pour un transfert, le compte débité.\n"
        'Les mots peuvent être mal transcrits par la dictée (« waze » pour '
        'Wave, « gaba » pour garba, « tantine » pour tontine).';

    final schema = <String, Object?>{
      'type': 'object',
      'properties': {
        'kind': {
          'type': 'string',
          'enum': ['expense', 'income', 'transfer'],
        },
        'amount': {'type': 'integer'},
        'category': {
          'type': 'string',
          'enum': [...categories.keys, 'none'],
        },
        'account': {
          'type': 'string',
          'enum': [...accounts.keys, 'none'],
        },
      },
      'required': ['kind', 'amount', 'category', 'account'],
      'additionalProperties': false,
    };
    return EntryAssistPrompt._(
      instruction: instruction,
      schema: schema,
      categories: categories,
      accounts: accounts,
    );
  }

  final String instruction;
  final Map<String, Object?> schema;

  /// Code → catégorie principale.
  final Map<String, Category> categories;

  /// Code → identifiant du compte.
  final Map<String, String> accounts;

  /// Vrai si l'opération a des champs que Gemma peut compléter.
  static bool needsHelp(ParsedOperation op) => op.uncertain.isNotEmpty;

  /// Remplit les champs incertains de [op] avec la réponse [rawJson] de
  /// Gemma. Une réponse illisible ou incohérente laisse [op] inchangée.
  ParsedOperation merge(ParsedOperation op, String rawJson) {
    final Map<String, Object?> answer;
    try {
      answer = (jsonDecode(rawJson) as Map).cast<String, Object?>();
    } on Object {
      return op;
    }
    var kind = op.kind;
    var categoryId = op.categoryId;
    var amount = op.amount;
    var accountId = op.accountId;

    if (op.uncertain.contains(ParsedField.category) &&
        op.kind != TransactionKind.transfer) {
      final category = categories[answer['category']];
      final answeredKind = switch (answer['kind']) {
        'income' => TransactionKind.income,
        'expense' => TransactionKind.expense,
        _ => null,
      };
      // La catégorie doit correspondre au type annoncé par Gemma.
      if (category != null &&
          answeredKind != null &&
          category.kind == answeredKind.categoryKind) {
        kind = answeredKind;
        categoryId = category.id;
      }
    }
    if (op.uncertain.contains(ParsedField.amount)) {
      final value = answer['amount'];
      if (value is int && value > 0) amount = Money(value);
    }
    if (op.uncertain.contains(ParsedField.account)) {
      accountId = accounts[answer['account']] ?? accountId;
    }

    return ParsedOperation(
      kind: kind,
      amount: amount,
      categoryId: categoryId,
      accountId: accountId,
      toAccountId: op.toAccountId,
      date: op.date,
      description: op.description,
      source: op.source,
      // Les champs complétés par Gemma restent « À vérifier ».
      uncertain: op.uncertain,
    );
  }
}
