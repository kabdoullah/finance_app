# 10 — Assistant IA (Gemma 4 et Copilote)

## Modèle
- **Gemma 4 E2B** au format LiteRT-LM (`gemma-4-E2B-it.litertlm`, 2,5 Go),
  téléchargé à la demande depuis Hugging Face (révision épinglée).
- **Compatibilité** : Android 11 ou iOS 15, 64 bits, ≥ 6 Go de mémoire
  (5,5 Go déclarés). Sinon, l'IA est « Indisponible », avec la raison.
- **Téléchargement** : 3 Go d'espace libre exigés ; confirmation sur
  données mobiles ; notification de progression ; annulable.
- **Chargement** refusé sous 2 Go de mémoire disponible ; contexte de 4 096
  jetons ; CPU sur Android, GPU Metal sur iPhone.
- Écran **Modèle IA** : états (vérification, indisponible, non installé,
  téléchargement, installé, chargement, prêt, erreur), « Charger
  maintenant », « Libérer la mémoire », « Charger l'IA au démarrage »
  (désactivé par défaut), « Supprimer le modèle » (les données ne sont pas
  touchées), état de la dictée.
- Internet n'est utilisé que pour ce téléchargement.

## Copilote (onglet Assistant)
**L'application calcule, Gemma explique.** Gemma choisit un **outil** et ses
paramètres ; l'application exécute l'outil avec les mêmes calculs que les
écrans ; Gemma rédige la phrase.

| Outil | Question type | Résultat affiché | Lien |
|---|---|---|---|
| Dépenses (aujourd'hui, semaine, mois, mois dernier ; catégorie) | « Combien cette semaine ? » | Total, répartition | Voir les opérations |
| Budgets | « Combien puis-je dépenser cette semaine ? » | Reste, jours, possible sur 7 jours | Voir mes budgets |
| Soldes | « Combien j'ai sur Wave ? » | Soldes, total | Voir mes comptes |
| Prévision 7/30/90 j | « Mon solde fin du mois ? » | Solde prévu, fourchette, fiabilité | Voir la prévision |
| Simulation d'achat | « Puis-je acheter un téléphone à 150 000 ? » | Verdict, point bas | Ouvrir la simulation (pré-remplie) |
| Préparer une opération | « Taxi 2 500 ce matin avec Wave » | Carte Enregistrer / Modifier | — |
| Bilan d'épargne | « Pourquoi j'ai du mal à économiser ? » | Revenus et dépenses moyens, part des charges fixes | Voir mes budgets |
| Objectif d'épargne | « Comment économiser 100 000 en 3 mois ? » | Par mois, épargne moyenne, échéance | Créer l'objectif (pré-rempli) |

### Garde-fous
- **Contrôle des nombres** : si la phrase de Gemma contient un nombre absent
  des résultats d'outils et de la question, la phrase écrite par
  l'application la remplace. Même chose quand l'outil n'a rien à montrer.
- Sans outil : réponse brève acceptée **seulement sans aucun chiffre**,
  sinon « Je n'ai pas bien compris… ». Pas de conseil de placement.
- Mention « Chiffres calculés par l'application · expliqués par Gemma 4 »
  sous toute réponse chiffrée.
- Sans période précisée, le mois en cours. Tutoiement.
- **Opération préparée** : lue par l'analyseur dans la phrase d'origine
  (pas dans la reformulation de Gemma) ; enregistrée seulement après
  « Enregistrer » (« Dépense enregistrée · solde Wave : … ») ; « Modifier »
  ouvre la saisie rapide pré-analysée.
- Pas de « piste d'économies » inventée.

### Conversation et historique
- Conversation Gemma gardée ouverte, repartie de zéro après 6 questions ou
  si le modèle est libéré ; 90 s au plus par réponse.
- **Historique** conservé dans la base chiffrée (500 messages au plus). Au
  redémarrage, il s'affiche mais Gemma repart sans mémoire ; une carte
  restée en attente devient « Non enregistrée ».
- « Effacer l'historique de conversation » dans les Paramètres.
- Pastilles de suggestion (5 questions types).

### Assistant non chargé
Écran « L'assistant n'est pas chargé » : raccourcis (Budgets, Prévisions,
Simuler un achat, Dicter) et bouton selon l'état (Charger, Installer, ou
rien si incompatible).
