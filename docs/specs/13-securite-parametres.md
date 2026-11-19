# 13 — Sécurité et paramètres

## Verrouillage
- **Code PIN à 4 chiffres**, choisi puis confirmé, avec l'avertissement :
  un code oublié ne peut pas être récupéré (sans serveur).
- Stockage : jamais le code ; empreinte **PBKDF2-HMAC-SHA256 salée**
  (100 000 itérations, hors du fil de l'interface) dans le coffre
  sécurisé ; comparaison à temps constant.
- **Biométrie facultative** (empreinte, visage, Face ID), activée après une
  reconnaissance réussie ; proposée automatiquement à l'écran de
  verrouillage.
- **Verrouiller après** : immédiatement, 1 minute (défaut) ou 5 minutes,
  au lancement et au retour d'arrière-plan (la fenêtre d'empreinte ne
  compte pas).
- **Essais** : après 5 codes faux, attente de 30 s, doublée à chaque
  nouvelle série (1 h au plus) ; compteur gardé dans le coffre ; même règle
  pour modifier ou désactiver le code.
- « Code oublié ? » : biométrie, sinon effacer les données de
  l'application dans les réglages du système.
- Le code **bloque l'accès** ; il ne chiffre pas la base (déjà chiffrée par
  sa propre clé). Coffre illisible : l'application s'ouvre plutôt que de
  rester bloquée.
- Verrouillage actif sur Android : contenu masqué dans les applications
  récentes, captures d'écran bloquées.

## Paramètres (dans l'ordre)
- « Données stockées uniquement sur ce téléphone ».
- **Préférences** : devise FCFA (XOF) et langue Français (lecture seule),
  thème (Automatique, Clair, Sombre), début du mois budgétaire, catégories
  (nombre), opérations récurrentes (actives), masquer les montants à
  l'ouverture.
- **Notifications** : 4 interrupteurs (voir [12](12-notifications.md)).
- **Sécurité et confidentialité** : verrouillage, code PIN, biométrie,
  verrouiller après ; « Aucune donnée n'est envoyée sur Internet, sauf le
  téléchargement du modèle IA si tu l'installes. »
- **Sauvegarde et données** : sauvegarde, restauration, export, Google
  Drive (à venir).
- **Assistant IA** : modèle Gemma 4, reconnaissance vocale, suggestions du
  Copilote, effacer l'historique de conversation.
- Pied de page : « Finao 1.0 · données stockées localement ».
