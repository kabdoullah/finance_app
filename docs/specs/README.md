# Finao — spécifications fonctionnelles

Finao est une application de finances personnelles pour la Côte d'Ivoire
(montants en FCFA), qui fonctionne **entièrement sur le téléphone** : saisie,
calculs, prévisions et assistant IA tournent hors connexion, sans compte et
sans serveur.

Ces specs décrivent **ce que fait l'application aujourd'hui** (état au
19 novembre 2026, commit `ecc1c1b`). Elles sont la référence pour toute
évolution : une règle qui change ici change aussi dans le code et ses tests.

## Principes communs

1. **Tout reste sur le téléphone.** Aucune donnée financière n'est envoyée
   sur Internet. Seule exception : le téléchargement du modèle IA (2,5 Go),
   à la demande de l'utilisateur.
2. **Base chiffrée.** Les données vivent dans une base SQLite chiffrée
   (SQLite3MultipleCiphers) dont la clé est rangée dans le coffre sécurisé
   du système (Keystore Android, Keychain iOS).
3. **L'application calcule, l'IA explique.** Soldes, budgets, prévisions et
   simulations sont calculés par des règles déterministes et testées. Gemma
   comprend les phrases et explique les résultats, mais n'invente aucun
   chiffre (contrôle automatique, voir [Assistant](10-assistant-ia.md)).
4. **Rien sans confirmation.** Dictée, texte libre, opérations préparées par
   le Copilote et échéances récurrentes « à confirmer » passent par un
   récapitulatif avant tout enregistrement.
5. **Sans IA, l'application reste complète.** Sur un téléphone incompatible
   ou sans le modèle, seules les réponses en langage naturel manquent.
6. **Transferts neutres.** Un transfert entre deux comptes de l'utilisateur
   n'est jamais compté comme revenu ni comme dépense.
7. **Montants entiers en FCFA.** Pas de centimes ; affichage « 25 000 FCFA »
   (espace insécable), signe moins typographique « − ».
8. **Portrait, tout texte.** Sur téléphone, l'application est bloquée en
   portrait (l'iPad garde toutes les orientations ; Android 16+ ignore le
   blocage sur tablettes et pliables). Les écrans tiennent dès 320 px de
   large et avec un texte agrandi jusqu'à ×2 : un libellé passe à la ligne
   ou se réduit, un montant n'est jamais tronqué. Pas de mise en page
   dédiée aux tablettes pour l'instant.

## Sommaire

| Fichier | Contenu |
|---|---|
| [01-architecture.md](01-architecture.md) | Technique : couches, base, migrations, plateformes, tests |
| [02-comptes.md](02-comptes.md) | Comptes, soldes, archivage |
| [03-operations.md](03-operations.md) | Dépenses, revenus, transferts, onglet Transactions |
| [04-saisie-rapide.md](04-saisie-rapide.md) | Saisie par texte ou dictée, analyseur, complétion par Gemma |
| [05-categories.md](05-categories.md) | Catégories et sous-catégories |
| [06-budgets.md](06-budgets.md) | Budgets, mois budgétaire, alertes |
| [07-recurrentes.md](07-recurrentes.md) | Opérations récurrentes |
| [08-previsions.md](08-previsions.md) | Prévision du solde, simulation d'achat |
| [09-objectifs.md](09-objectifs.md) | Objectifs d'épargne, fonds d'urgence |
| [10-assistant-ia.md](10-assistant-ia.md) | Modèle Gemma, Copilote, outils, historique |
| [11-accueil.md](11-accueil.md) | Accueil, suggestions du Copilote, carte prévision |
| [12-notifications.md](12-notifications.md) | Rappels, alertes, solde bas, rappel de sauvegarde |
| [13-securite-parametres.md](13-securite-parametres.md) | Verrouillage, paramètres, confidentialité |
| [14-sauvegarde-export.md](14-sauvegarde-export.md) | Sauvegarde chiffrée, restauration, export CSV/PDF |
| [15-depenses-planifiees.md](15-depenses-planifiees.md) | Dépenses planifiées : création, paiement, retard, effet sur les prévisions |

## Hors périmètre (prévu plus tard)

- Google Drive intégré (synchronisation automatique) : prochaine version.
  Aujourd'hui, Drive est accessible via le sélecteur de fichiers du système.
- Scanner de reçus (l'origine « reçu » existe dans le modèle de données).
- Mise en page tablette (navigation latérale, largeur de contenu limitée).
- Publication : identifiant `com.finao.app` choisi ; clé de signature de
  publication (Android) et compte développeur Apple payant à prévoir.

## Glossaire

- **Mois budgétaire** : période de calcul des budgets et totaux du mois,
  du 1er par défaut, réglable du 1er au 28.
- **Disponible** : solde d'un compte moins l'argent réservé aux objectifs.
- **Copilote** : l'assistant de l'application (langage naturel, Gemma 4).
- **À vérifier** : champ deviné par l'analyseur ou par Gemma, que
  l'utilisateur doit confirmer.
