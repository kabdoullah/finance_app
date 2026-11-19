# 07 — Opérations récurrentes

Modèles de dépense ou de revenu (loyer, salaire, abonnements, tontine…).
**Un modèle ne change aucun solde** tant que l'échéance n'est pas
enregistrée ; il sert aux prévisions et aux rappels.

## Modèle
- Nom (80 caractères au plus), montant **fixe ou variable** (estimation),
  catégorie, compte.
- Fréquence : **chaque semaine, chaque mois ou chaque année**, à partir
  d'une date de début ; date de fin facultative.
- Calcul des échéances depuis la date de début (un 31 redevient le 31 après
  un mois court ; un 29–31 tombe le dernier jour des mois plus courts).
- **Avec confirmation** (« Me demander avant d'enregistrer ») ou
  **automatique**.
- Pause et reprise ; suppression (les opérations déjà enregistrées
  restent).

## Échéances
- **À confirmer** : listées (« échéance hier »), de la plus ancienne à la
  plus récente ; seule la plus ancienne d'un modèle se traite. Actions :
  enregistrer (montant modifiable si variable) ou passer.
- **Automatiques** : enregistrées à l'ouverture de l'application et à chaque
  retour au premier plan, à leur date ; les échéances manquées sont
  rattrapées (pas de service en arrière-plan).
- Origine des opérations : « Récurrente ».

## Totaux
« Revenus prévus / mois » et « Dépenses prévues / mois » des modèles
actifs (hebdomadaire × 52 ÷ 12, annuel ÷ 12). Les charges fixes du bilan
d'épargne du Copilote en dépendent.
