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
- **Période** : Jour, Semaine (lundi → dimanche), Mois (mois budgétaire,
  avec ses dates s'il ne commence pas le 1er) ou Période (dates choisies au
  calendrier ou raccourcis : 7 derniers jours, ce mois-ci, 30 prochains
  jours, 3 derniers mois). Flèches précédent / suivant (sauf Période). Au
  changement de pas, la période garde aujourd'hui si elle le contient,
  sinon son premier jour. Gardée tant que l'application est ouverte ; mois
  en cours au lancement.
- **Résumé** : Payées (dépenses), Planifiées (dépenses à payer de la
  période), nombre d'opérations ; « Revenus +… · transferts exclus des
  totaux » s'il y a des revenus.
- **Statuts** : Tout, Payées, Planifiées, « En retard · N » s'il y en a.
  Groupes « En retard » et « À venir » (dépenses planifiées et échéances
  récurrentes de la période) puis opérations par jour.
- **Filtres** (feuille) : type, catégorie principale, compte ; « Voir N
  opérations », « Réinitialiser » ; filtres actifs en pastilles
  retirables. Recherche derrière la loupe, sans accents ni majuscules.
- États : chargement (lignes grisées), « Rien sur cette période » /
  « Aucun résultat » avec « Tout afficher », premier lancement (Ajouter,
  Planifier une dépense, Dicter).
- Depuis un budget, « Voir les opérations » ouvre le mois en cours filtré
  sur sa catégorie ; depuis Dépenses du mois, le mois choisi.

## « Où va ton argent »
Dépenses du mois par catégorie principale, de la plus grande à la plus
petite ; 5 parts au plus (les plus petites regroupées en « Autres ») ;
pourcentages entiers dont la somme vaut toujours 100.
