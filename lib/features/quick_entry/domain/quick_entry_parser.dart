import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_type.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction.dart';

/// Champ deviné sans certitude : affiché « À vérifier » au récapitulatif.
enum ParsedField { amount, category, account }

/// Une opération comprise dans une saisie rapide (texte ou voix).
@immutable
class ParsedOperation {
  const ParsedOperation({
    required this.kind,
    required this.date,
    required this.description,
    this.source = '',
    this.amount,
    this.categoryId,
    this.accountId,
    this.toAccountId,
    this.uncertain = const {},
  });

  final TransactionKind kind;
  final Money? amount;
  final String? categoryId;
  final String? accountId;

  /// Compte crédité d'un transfert.
  final String? toAccountId;

  /// Jour de l'opération (date calendaire locale).
  final DateTime date;

  /// Description proposée (morceau de phrase sans montant ni date).
  final String description;

  /// Morceau de phrase d'origine, tel que dit ou écrit (envoyé à Gemma).
  final String source;
  final Set<ParsedField> uncertain;
}

/// Ce que l'analyseur connaît de l'utilisateur.
@immutable
class QuickEntryContext {
  const QuickEntryContext({
    required this.now,
    required this.accounts,
    required this.expenseGroups,
    required this.incomeGroups,
    this.defaultAccountId,
  });

  final DateTime now;

  /// Comptes actifs.
  final List<Account> accounts;
  final List<CategoryGroup> expenseGroups;
  final List<CategoryGroup> incomeGroups;

  /// Compte proposé quand la phrase n'en cite aucun (le dernier utilisé).
  final String? defaultAccountId;
}

/// Analyseur déterministe de la saisie rapide : fonctionne sans IA, en
/// quelques millisecondes. Dictionnaire de variantes ivoiriennes et de
/// déformations de la reconnaissance vocale (« waze » → Wave, « tantine » →
/// tontine…).
class QuickEntryParser {
  const QuickEntryParser();

  /// Mots qui désignent une catégorie par défaut ou une sous-catégorie.
  static const _categoryAliases = <String, List<String>>{
    'exp.food': ['nourriture', 'manger', 'riz', 'poisson', 'viande'],
    'exp.food.market': ['marche', 'courses'],
    'exp.food.restaurant': [
      'restaurant',
      'resto',
      'maquis',
      'garba',
      'gaba',
      'dibiterie',
      'alloco',
      'dejeuner',
      'diner',
      'repas',
    ],
    'exp.food.bakery': ['pain', 'boulangerie', 'croissant'],
    'exp.transport': ['transport', 'bus', 'sotra', 'moto'],
    'exp.transport.taxi': ['taxi', 'taxis', 'yango'],
    'exp.transport.woro': ['woro', 'woro woro', 'goro goro'],
    'exp.transport.gbaka': ['gbaka'],
    'exp.transport.fuel': ['carburant', 'essence', 'gasoil', 'gazoil'],
    'exp.housing.rent': ['loyer'],
    'exp.housing.upkeep': ['entretien', 'reparation'],
    'exp.bills.electricity': ['courant', 'electricite', 'cie', 'lumiere'],
    'exp.bills.water': ['eau', 'sodeci'],
    'exp.bills.internet': ['internet', 'wifi', 'data'],
    'exp.bills.airtime': ['credit', 'credit telephone', 'unites', 'recharge'],
    'exp.leisure.outings': ['cinema', 'sortie', 'sorties', 'boite'],
    'exp.leisure.subscriptions': ['abonnement', 'canal', 'netflix'],
    'exp.health.pharmacy': ['pharmacie', 'medicament', 'medicaments'],
    'exp.health.consultation': [
      'consultation',
      'hopital',
      'docteur',
      'medecin',
      'clinique',
    ],
    'exp.family': ['famille', 'village', 'envoi au village'],
    'exp.tontine': ['tontine', 'tantine', 'cotisation'],
    'exp.education': ['ecole', 'scolarite', 'cours', 'fournitures', 'livres'],
    'exp.clothing': [
      'habits',
      'vetements',
      'pagne',
      'chaussures',
      'tissu',
      'couture',
    ],
    'inc.salary': ['salaire', 'paie', 'paye'],
    'inc.missions': ['mission', 'prestation'],
    'inc.missions.freelance': ['freelance'],
    'inc.missions.consulting': ['consulting'],
    'inc.sale': ['vente', 'vendu', 'vendre'],
    'inc.received.family': [
      'maman',
      'papa',
      'frere',
      'soeur',
      'tonton',
      'tata',
      'famille',
    ],
    'inc.received.refund': ['remboursement', 'rembourse'],
  };

  /// Indices d'un revenu (en plus des catégories de revenus).
  static const _incomeWords = [
    'recu',
    'recus',
    'm a envoye',
    'ma envoye',
    'm a donne',
    'encaisse',
    'gagne',
  ];

  static const _transferWords = ['transfert', 'transfere', 'vire', 'virement'];

  static final _amountPattern = RegExp(
    r'(\d{1,3}(?: \d{3})+|\d+)(?:,(\d+))?\s*(k|mille|mil|millions?|m)?\b',
  );

  List<ParsedOperation> parse(String text, QuickEntryContext context) {
    final today = CalendarDate.of(context.now);
    final operations = <ParsedOperation>[];
    // Une date dite au début (« Hier, … et … ») vaut pour les opérations
    // suivantes, sauf si l'une d'elles en précise une autre.
    var date = today;
    for (final segment in _segments(text)) {
      final op = _parseSegment(segment, context, today, date);
      if (op == null) continue;
      operations.add(op);
      date = op.date;
    }
    return _shareAccount(operations);
  }

  /// « Déjeuner 2 500 et taxi 1 000 avec Wave » : quand la phrase ne cite
  /// qu'un seul compte, il vaut pour les opérations qui n'en citent pas.
  List<ParsedOperation> _shareAccount(List<ParsedOperation> operations) {
    final cited = {
      for (final op in operations)
        if (op.kind != TransactionKind.transfer &&
            !op.uncertain.contains(ParsedField.account))
          op.accountId,
    };
    if (cited.length != 1) return operations;
    return [
      for (final op in operations)
        op.uncertain.contains(ParsedField.account)
            ? ParsedOperation(
                kind: op.kind,
                amount: op.amount,
                categoryId: op.categoryId,
                accountId: cited.single,
                date: op.date,
                description: op.description,
                source: op.source,
                uncertain: op.uncertain.difference({ParsedField.account}),
              )
            : op,
    ];
  }

  /// Découpe « 2 000 de crédit et 1 500 de pain » en deux opérations, sauf
  /// quand un morceau n'a pas de montant (il reste attaché au précédent).
  List<String> _segments(String text) {
    final parts = text
        .split(RegExp(r'\s*(?:[;\n]|,(?!\d)|\bet\b|\bpuis\b)\s*'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final merged = <String>[];
    for (final part in parts) {
      if (merged.isNotEmpty && _amounts(_normalize(part)).isEmpty) {
        merged[merged.length - 1] = '${merged.last} $part';
      } else {
        merged.add(part);
      }
    }
    // Un éventuel morceau de tête sans montant (« Hier, … ») se rattache au
    // suivant.
    if (merged.length > 1 && _amounts(_normalize(merged.first)).isEmpty) {
      merged[1] = '${merged[0]} ${merged[1]}';
      merged.removeAt(0);
    }
    return merged;
  }

  ParsedOperation? _parseSegment(
    String original,
    QuickEntryContext context,
    DateTime today,
    DateTime inheritedDate,
  ) {
    final text = _normalize(original);
    if (text.isEmpty) return null;
    final uncertain = <ParsedField>{};

    // Montant.
    final amounts = _amounts(text);
    final amount = amounts.isEmpty ? null : amounts.first;
    if (amounts.length != 1) uncertain.add(ParsedField.amount);

    // Date.
    final date = _has(text, 'avant hier')
        ? DateTime(today.year, today.month, today.day - 2)
        : _has(text, 'hier')
        ? DateTime(today.year, today.month, today.day - 1)
        : _has(text, 'aujourd hui')
        ? today
        : inheritedDate;

    // Comptes cités, dans l'ordre de la phrase.
    final mentioned = _accountsIn(text, context.accounts);

    // Transfert : un mot de transfert et deux comptes, ou « de X vers Y ».
    final isTransfer =
        mentioned.length >= 2 &&
        (_transferWords.any((w) => _has(text, w)) ||
            RegExp(r'\bde\b.*\b(vers|a|sur)\b').hasMatch(text));
    if (isTransfer) {
      return ParsedOperation(
        kind: TransactionKind.transfer,
        amount: amount,
        accountId: mentioned[0].id,
        toAccountId: mentioned[1].id,
        date: date,
        description: _description(original),
        source: original.trim(),
        uncertain: uncertain,
      );
    }

    // Catégorie : recherche dans les revenus puis les dépenses ; la plus
    // longue expression trouvée l'emporte.
    final income = _matchCategory(text, context.incomeGroups);
    final expense = _matchCategory(text, context.expenseGroups);
    final incomeHint = _incomeWords.any((w) => _has(text, w));
    final TransactionKind kind;
    final _Match? match;
    if (income != null &&
        (expense == null || incomeHint || income.length >= expense.length)) {
      kind = TransactionKind.income;
      match = income;
    } else if (incomeHint && expense == null) {
      kind = TransactionKind.income;
      match = null;
    } else {
      kind = TransactionKind.expense;
      match = expense;
    }
    final categoryId =
        match?.categoryId ??
        (kind == TransactionKind.income
            ? CategoryKind.income.fallbackId
            : CategoryKind.expense.fallbackId);
    if (match == null) uncertain.add(ParsedField.category);

    // Compte : celui cité, sinon le dernier utilisé (à vérifier).
    var accountId = mentioned.isEmpty ? null : mentioned.first.id;
    if (accountId == null) {
      accountId = context.defaultAccountId;
      uncertain.add(ParsedField.account);
    }

    return ParsedOperation(
      kind: kind,
      amount: amount,
      categoryId: categoryId,
      accountId: accountId,
      date: date,
      description: _description(original),
      source: original.trim(),
      uncertain: uncertain,
    );
  }

  // ---------------------------------------------------------------------------
  // Montants.

  List<Money> _amounts(String text) {
    final found = <Money>[];
    for (final m in _amountPattern.allMatches(text)) {
      final digits = m.group(1)!.replaceAll(' ', '');
      final decimals = m.group(2);
      var value = double.parse(decimals == null ? digits : '$digits.$decimals');
      final unit = m.group(3);
      if (unit == 'k' || unit == 'mille' || unit == 'mil') value *= 1000;
      if (unit == 'm' || (unit?.startsWith('million') ?? false)) {
        value *= 1000000;
      }
      if (value >= 1) found.add(Money(value.round()));
    }
    if (found.isEmpty) {
      final spelled = _spelledAmount(text);
      if (spelled != null) found.add(spelled);
    }
    return found;
  }

  static const _units = {
    'zero': 0,
    'un': 1,
    'une': 1,
    'deux': 2,
    'trois': 3,
    'quatre': 4,
    'cinq': 5,
    'six': 6,
    'sept': 7,
    'huit': 8,
    'neuf': 9,
    'dix': 10,
    'onze': 11,
    'douze': 12,
    'treize': 13,
    'quatorze': 14,
    'quinze': 15,
    'seize': 16,
    'vingt': 20,
    'vingts': 20,
    'trente': 30,
    'quarante': 40,
    'cinquante': 50,
    'soixante': 60,
  };

  /// « trois cent quatre vingt mille » → 380 000 ; « mille » seul → 1 000.
  /// Centaines et reste sont séparés : « quatre vingt » ne multiplie que
  /// l'unité qui le précède.
  Money? _spelledAmount(String text) {
    var total = 0;
    var hundreds = 0;
    var rest = 0;
    var seen = false;
    for (final word in text.split(' ')) {
      final unit = _units[word];
      if (unit != null) {
        rest = (word.startsWith('vingt') && rest > 0 && rest < 10)
            ? rest * 20
            : rest + unit;
        seen = true;
      } else if (word == 'cent' || word == 'cents') {
        hundreds = (rest == 0 ? 1 : rest) * 100;
        rest = 0;
        seen = true;
      } else if (word == 'mille' || word == 'mil') {
        final group = hundreds + rest;
        total += (group == 0 ? 1 : group) * 1000;
        hundreds = 0;
        rest = 0;
        seen = true;
      } else if (word == 'million' || word == 'millions') {
        final group = hundreds + rest;
        total += (group == 0 ? 1 : group) * 1000000;
        hundreds = 0;
        rest = 0;
        seen = true;
      } else if (seen && word != 'et' && total + hundreds + rest > 0) {
        break; // Fin du nombre.
      }
    }
    final value = total + hundreds + rest;
    return seen && value > 0 ? Money(value) : null;
  }

  // ---------------------------------------------------------------------------
  // Catégories et comptes.

  _Match? _matchCategory(String text, List<CategoryGroup> groups) {
    _Match? best;
    void consider(Category category, String phrase) {
      final normalized = _normalize(phrase);
      if (normalized.isEmpty || !_has(text, normalized)) return;
      if (best == null || normalized.length > best!.length) {
        best = _Match(category.id, normalized.length);
      }
    }

    for (final group in groups) {
      if (group.category.isHidden) continue;
      for (final category in [group.category, ...group.visibleChildren]) {
        consider(category, category.name);
        for (final alias in _categoryAliases[category.id] ?? const <String>[]) {
          consider(category, alias);
        }
      }
    }
    return best;
  }

  List<Account> _accountsIn(String text, List<Account> accounts) {
    final hits = <(int, Account)>[];
    for (final account in accounts) {
      final positions = [
        for (final alias in _accountAliases(account))
          if (_position(text, alias) case final p? when p >= 0) p,
      ];
      if (positions.isNotEmpty) {
        hits.add((positions.reduce((a, b) => a < b ? a : b), account));
      }
    }
    hits.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final (_, account) in hits) account];
  }

  /// Nom du compte, plus les variantes connues de l'opérateur et les
  /// déformations de la reconnaissance vocale.
  static List<String> _accountAliases(Account account) {
    final name = _normalize(account.name);
    return {
      name,
      if (name.contains('wave')) ...['wave', 'waze', 'ouave', 'wav'],
      if (name.contains('orange')) ...['orange', 'om', 'orange money'],
      if (name.contains('mtn')) ...['mtn', 'momo', 'mtn money'],
      if (name.contains('moov')) ...['moov', 'flooz'],
      if (account.type == AccountType.cash) ...[
        'especes',
        'espece',
        'cash',
        'liquide',
      ],
      if (account.type == AccountType.bank) 'banque',
    }.toList();
  }

  // ---------------------------------------------------------------------------
  // Texte.

  /// Minuscules, sans accents ni ponctuation, montants « 2.000 » → « 2 000 ».
  static String _normalize(String text) {
    var s = text.toLowerCase();
    const accents = {
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'î': 'i',
      'ï': 'i',
      'ô': 'o',
      'ö': 'o',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    accents.forEach((from, to) => s = s.replaceAll(from, to));
    s = s
        .replaceAll(RegExp(r"[’'\-]"), ' ')
        .replaceAll(RegExp(r'(?<=\d)[.  ](?=\d{3}\b)'), ' ')
        .replaceAll(RegExp(r'\b(f ?cfa|cfa|francs?|f)\b'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9, ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return s;
  }

  static bool _has(String text, String phrase) =>
      (_position(text, phrase) ?? -1) >= 0;

  /// Position du mot ou de l'expression (mots entiers), ou -1.
  static int? _position(String text, String phrase) {
    final match = RegExp('(^| )${RegExp.escape(phrase)}( |\$)')
        .firstMatch(text);
    return match?.start ?? -1;
  }

  /// Morceau de phrase sans le montant ni la date : « Hier, 2 000 de crédit
  /// Orange » → « Crédit Orange ».
  static String _description(String original) {
    final trimmed = original
        .replaceAll(
          RegExp(
            r'\d[\d .\u00a0\u202f]*(?:,\d+)?\s*(?:k|mille|mil|millions?)?\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(r'\b(?:f ?cfa|cfa|francs?|fr)\b', caseSensitive: false),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceFirst(
          RegExp(
            r"^(?:(?:avant[- ]hier|hier|aujourd['’]hui)\b[\s,]*)?(?:de\s+|d['’]\s*)?",
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'^[\s,;.:]+|[\s,;.:]+$'), '');
    if (trimmed.isEmpty) return trimmed;
    final capitalized = trimmed[0].toUpperCase() + trimmed.substring(1);
    return capitalized.length > 80 ? capitalized.substring(0, 80) : capitalized;
  }
}

class _Match {
  const _Match(this.categoryId, this.length);

  final String categoryId;
  final int length;
}
