# 15 — Dépenses planifiées

Dépense ponctuelle à payer plus tard (scolarité, réparation…), avec une
**date prévue**. **Elle ne change aucun solde** tant qu'elle n'est pas
marquée payée. Les modèles réguliers relèvent des
[opérations récurrentes](07-recurrentes.md).

## Création et modification
- Ajouter › Dépense › montant › **Payée / Planifiée**.
- Planifiée : libellé obligatoire (80 caractères), catégorie de dépense,
  compte actif, **date prévue après aujourd'hui** (demain par défaut),
  note facultative (80 caractères).
- Modifiable tant qu'elle n'est pas payée ; une dépense en retard garde sa
  date passée ou passe à une date future.
- Suppression avec « Annuler la suppression ».

## Statut
- **Planifiée** : date prévue aujourd'hui ou plus tard.
- **En retard** : date prévue passée, pas encore payée ; elle reste à payer.
- **Payée** : « Marquer comme payée » (aujourd'hui, hier, ou la date prévue
  si elle est plus ancienne ; jamais dans le futur). Elle devient une
  **dépense ordinaire** à la date réelle (heure actuelle si aujourd'hui,
  midi sinon), qui garde la date prévue, la date de création et la note,
  et quitte les dépenses planifiées : **jamais comptée deux fois**.
- Une dépense payée ne se modifie plus que comme opération ; supprimer
  cette opération supprime aussi la dépense planifiée (« Annuler » remet
  tout). Détail de l'opération : « Date prévue », « Payée en avance » si
  payée avant.

## Où elles comptent
- Mois : non payée → mois (budgétaire) de la date prévue ; payée → mois du
  paiement réel.
- Transactions : groupes « En retard » et « À venir » en haut du mois
  affiché (« … à payer »), selon les filtres type, compte, catégorie et la
  recherche.
- Prévisions : sortie à la date prévue ; en retard, comptée dès demain.
  Payée, elle n'entre pas dans la moyenne des dépenses courantes (comme les
  échéances récurrentes) : payer en avance ne change pas la prévision à la
  date prévue.
- Budgets : seulement une fois payée (comme toute dépense).
- Notification : rappel à 9 h le jour prévu (interrupteur « Rappels
  d'échéance »), qui ouvre son détail.

## Données
Table `planned_expenses` (schéma v9) pour les dépenses à payer ; colonnes
`planned_due_date`, `planned_created_at`, `planned_note` sur `transactions`
pour celles payées. Supprimer une catégorie déplace ses dépenses
planifiées vers la catégorie de repli.
