# 08 — Prévisions et simulation d'achat

## Prévision du solde (moteur déterministe, sans IA)
- Horizons : **7, 30 et 90 jours**, à partir d'aujourd'hui.
- Disponible après **14 jours d'historique** ; avant, écran « Pas encore
  assez de données » avec la progression.
- Calcul : solde total actuel + échéances récurrentes de la période (en
  retard comptées aujourd'hui) − dépenses variables moyennes par jour
  (90 derniers jours, opérations récurrentes exclues).
- **Fourchette** : écart type des dépenses variables × √jours, arrondie aux
  5 000 FCFA. Solde prévu arrondi au millier.
- **Fiabilité** : élevée (7 j), moyenne (30 j), faible (90 j) ; un cran de
  moins avec moins de 30 jours d'historique.
- **Risques** : solde sous zéro (date), **solde bas possible** (point le
  plus bas sous 7 jours de dépenses variables, « juste avant ton salaire »
  si un revenu arrive le lendemain), budgets qui seront dépassés dans la
  période (avec la dépense moyenne par jour).
- Courbe : historique récent + prévision ; « Ce qui est attendu » (revenus
  et dépenses de la période).

## Simulation d'achat (« Puis-je acheter … ? »)
- Prix, nom facultatif, jour d'achat : aujourd'hui ou après le prochain
  revenu récurrent ; option « Utiliser mon épargne » si un objectif porte le
  même nom.
- Calcul sur la prévision à 30 jours, sur le **disponible** (solde −
  réserves des objectifs).
- Verdict : **possible**, **serré** (point bas sous 7 jours de dépenses) ou
  **déconseillé** (passage sous zéro, avec la date). Disponible le plus bas
  et fin de période avec et sans l'achat, arrondis au millier.
- Actions : « Créer un objectif pour cet achat », « En parler au Copilote »
  (question posée automatiquement si l'assistant est chargé).
- Rien n'est enregistré : pure hypothèse.
