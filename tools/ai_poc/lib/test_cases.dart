// Jeux de test FICTIFS du POC (aucune donnée réelle de l'utilisateur).
//
// 1. Questions de l'assistant → appel d'outil attendu (le modèle interprète,
//    les outils calculent : règle du projet).
// 2. Saisies rapides → champs JSON attendus.

/// Catégories principales de l'application (dépenses puis revenus).
const expenseCategories = [
  'Alimentation',
  'Transport',
  'Logement',
  'Factures',
  'Loisirs',
  'Santé',
  'Famille',
  'Tontine',
  'Éducation',
  'Habillement',
  'Autre',
];
const incomeCategories = ['Salaire', 'Ventes', 'Argent reçu', 'Autre revenu'];
const accounts = ['Espèces', 'Wave', 'Orange Money', 'MTN MoMo', 'Ecobank'];

class ToolCase {
  const ToolCase(this.question, this.tool, [this.args = const {}]);

  final String question;
  final String tool;

  /// Arguments attendus (les autres arguments éventuels sont ignorés).
  final Map<String, Object> args;
}

const toolCases = [
  ToolCase("Combien j'ai dépensé en transport ce mois ?", 'get_spending', {
    'category': 'Transport',
    'period': 'this_month',
  }),
  ToolCase("J'ai mis combien dans le wôrô-wôrô ce mois-ci ?", 'get_spending', {
    'category': 'Transport',
    'period': 'this_month',
  }),
  ToolCase('Mes dépenses de nourriture le mois passé ?', 'get_spending', {
    'category': 'Alimentation',
    'period': 'last_month',
  }),
  ToolCase("Combien j'ai dépensé aujourd'hui ?", 'get_spending', {
    'period': 'today',
  }),
  ToolCase("J'ai dépensé combien cette semaine ?", 'get_spending', {
    'period': 'this_week',
  }),
  ToolCase("Combien j'ai dépensé pour la tontine ce mois ?", 'get_spending', {
    'category': 'Tontine',
    'period': 'this_month',
  }),
  ToolCase(
    'Mes factures de courant ce mois, ça fait combien ?',
    'get_spending',
    {'category': 'Factures', 'period': 'this_month'},
  ),
  ToolCase(
    'Il me reste combien sur mon budget Alimentation ?',
    'get_budget_status',
    {'category': 'Alimentation'},
  ),
  ToolCase(
    "Est-ce que j'ai dépassé mon budget transport ?",
    'get_budget_status',
    {'category': 'Transport'},
  ),
  ToolCase(
    'Combien il me reste sur le budget loisirs ce mois ?',
    'get_budget_status',
    {'category': 'Loisirs'},
  ),
  ToolCase('Quel budget je risque de dépasser ?', 'get_budget_status'),
  ToolCase("C'est quoi mon solde Wave ?", 'get_balance', {'account': 'Wave'}),
  ToolCase("J'ai combien sur Orange Money ?", 'get_balance', {
    'account': 'Orange Money',
  }),
  ToolCase("Combien j'ai en tout sur mes comptes ?", 'get_balance'),
  ToolCase('Dans 30 jours je vais avoir combien ?', 'get_forecast', {
    'days': 30,
  }),
  ToolCase('Mon solde dans une semaine, ça donne quoi ?', 'get_forecast', {
    'days': 7,
  }),
  ToolCase('Dans 3 mois mon solde sera comment ?', 'get_forecast', {
    'days': 90,
  }),
  ToolCase(
    'Est-ce que je peux acheter une moto à 450 000 ?',
    'simulate_purchase',
    {'price': 450000},
  ),
  ToolCase(
    "Je veux acheter un téléphone de 150 mille, c'est possible ?",
    'simulate_purchase',
    {'price': 150000},
  ),
  ToolCase(
    "Je peux payer un frigo à 200 000 F aujourd'hui ?",
    'simulate_purchase',
    {'price': 200000},
  ),
];

class EntryCase {
  const EntryCase(this.text, this.expected);

  final String text;

  /// kind, amount, category, account, date (today | yesterday).
  final Map<String, Object?> expected;
}

Map<String, Object?> _e(
  String kind,
  int amount,
  String? category,
  String? account, [
  String date = 'today',
]) => {
  'kind': kind,
  'amount': amount,
  'category': category,
  'account': account,
  'date': date,
};

final entryCases = [
  EntryCase('taxi 2000 wave', _e('expense', 2000, 'Transport', 'Wave')),
  EntryCase(
    'wôrô 500 espèces hier',
    _e('expense', 500, 'Transport', 'Espèces', 'yesterday'),
  ),
  EntryCase(
    'salaire 380000 sur ecobank',
    _e('income', 380000, 'Salaire', 'Ecobank'),
  ),
  EntryCase(
    'marché 7500 orange money',
    _e('expense', 7500, 'Alimentation', 'Orange Money'),
  ),
  EntryCase('gbaka 300', _e('expense', 300, 'Transport', null)),
  EntryCase(
    'loyer 75 000 ecobank',
    _e('expense', 75000, 'Logement', 'Ecobank'),
  ),
  EntryCase('courant CIE 14000 wave', _e('expense', 14000, 'Factures', 'Wave')),
  EntryCase(
    'crédit téléphone 1000 orange',
    _e('expense', 1000, 'Factures', 'Orange Money'),
  ),
  EntryCase(
    'tontine 40 mille espèces',
    _e('expense', 40000, 'Tontine', 'Espèces'),
  ),
  EntryCase(
    "maman m'a envoyé 20000 sur wave",
    _e('income', 20000, 'Argent reçu', 'Wave'),
  ),
  EntryCase('pharmacie 3500', _e('expense', 3500, 'Santé', null)),
  EntryCase(
    'garba 1000 hier',
    _e('expense', 1000, 'Alimentation', null, 'yesterday'),
  ),
  EntryCase(
    'carburant 10 000 espèces',
    _e('expense', 10000, 'Transport', 'Espèces'),
  ),
  EntryCase(
    'frais de scolarité 50000 ecobank',
    _e('expense', 50000, 'Éducation', 'Ecobank'),
  ),
  EntryCase('pagne 12000 wave', _e('expense', 12000, 'Habillement', 'Wave')),
  EntryCase(
    'envoi au village 25000 mtn',
    _e('expense', 25000, 'Famille', 'MTN MoMo'),
  ),
  EntryCase(
    "vente d'attiéké 15000 espèces",
    _e('income', 15000, 'Ventes', 'Espèces'),
  ),
  EntryCase(
    'cinéma 4000 hier wave',
    _e('expense', 4000, 'Loisirs', 'Wave', 'yesterday'),
  ),
  EntryCase(
    'transfert 50000 de ecobank vers wave',
    _e('transfer', 50000, null, 'Ecobank'),
  ),
  EntryCase(
    'restaurant 6500 orange money',
    _e('expense', 6500, 'Alimentation', 'Orange Money'),
  ),
];

/// Phrases lues à voix haute (2e série), avec l'opération attendue en codes
/// stables (catégorie, compte).
class VoicePhrase {
  const VoicePhrase(this.text, this.expected);

  final String text;
  final Map<String, Object?> expected;
}

Map<String, Object?> _v(
  String kind,
  int amount,
  String? category,
  String? account, [
  String date = 'today',
]) => {
  'kind': kind,
  'amount': amount,
  'category': category,
  'account': account,
  'date': date,
};

final voicePhrases = [
  VoicePhrase(
    'taxi deux mille sur Wave',
    _v('expense', 2000, 'transport', 'wave'),
  ),
  VoicePhrase(
    'salaire trois cent quatre-vingt mille sur Ecobank',
    _v('income', 380000, 'salary', 'ecobank'),
  ),
  VoicePhrase(
    'garba mille hier',
    _v('expense', 1000, 'food', null, 'yesterday'),
  ),
  VoicePhrase(
    'wôrô-wôrô cinq cents espèces',
    _v('expense', 500, 'transport', 'cash'),
  ),
  VoicePhrase('tontine quarante mille', _v('expense', 40000, 'tontine', null)),
  VoicePhrase(
    'crédit téléphone mille francs Orange Money',
    _v('expense', 1000, 'bills', 'orange_money'),
  ),
  VoicePhrase(
    "maman m'a envoyé vingt mille sur Wave",
    _v('income', 20000, 'money_received', 'wave'),
  ),
  VoicePhrase(
    'transfert cinquante mille de Ecobank vers Wave',
    _v('transfer', 50000, null, 'ecobank'),
  ),
];
