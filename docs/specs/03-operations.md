# 03 — Opérations (dépenses, revenus, transferts)

## Modèle
| Champ | Règle |
|---|---|
| Type | Dépense, Revenu ou Transfert |
| Montant | Entier positif, 999 999 999 FCFA au plus ; le sens dépend du type |
| Compte | Compte débité (dépense, transfert) ou crédité (revenu), actif |
| Vers le compte | Transfert uniquement, différent du compte débité |
| Catégorie | Dépense ou revenu : catégorie ou sous-catégorie du bon type. Transfert : aucune |
| Date et heure | Libre (passé compris) |
| Description | Facultative, 80 caractères au plus |
| Origine (« Saisie ») | Manuelle, Dictée, Texte, Reçu, Récurrente |

La **catégorie principale** (parente d'une sous-catégorie) est celle qui
compte pour les budgets et la répartition.

## Actions
Créer, modifier, **dupliquer** (copie modifiable d'une opération existante),
supprimer avec **annulation** (la suppression peut être défaite depuis le
message qui la confirme).

## Onglet Transactions
- Un **mois budgétaire** à la fois (12 derniers au choix), avec ses dates
  si le mois ne commence pas le 1er (« Novembre · 25 oct. – 24 nov. »).
- Filtres : type, compte, catégorie ; recherche texte sans accents ni
  majuscules ; « Réinitialiser ».
- Totaux revenus / dépenses de la sélection, **transferts exclus**.
- Depuis un budget, « Voir les opérations » ouvre l'onglet filtré sur sa
  catégorie.

## « Où va ton argent »
Dépenses du mois par catégorie principale, de la plus grande à la plus
petite ; 5 parts au plus (les plus petites regroupées en « Autres ») ;
pourcentages entiers dont la somme vaut toujours 100.
