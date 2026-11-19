# 01 — Architecture technique

## Pile

| Domaine | Choix |
|---|---|
| Interface | Flutter, `material_ui`, police Manrope, icônes Phosphor |
| État | Riverpod 3 (providers, notifiers) |
| Navigation | go_router (5 onglets : Accueil, Transactions, Budgets, Prévisions, Assistant) |
| Base | drift + SQLite3MultipleCiphers (chiffrement), migrations pas à pas |
| Secrets | flutter_secure_storage (Keystore / Keychain) |
| Préférences | shared_preferences (réglages non financiers) |
| IA | flutter_edge_ai + LiteRT-LM, Gemma 4 E2B (`.litertlm`, 2,5 Go) |
| Notifications | flutter_local_notifications (locales, sans serveur) |
| Biométrie | local_auth |
| Cryptographie | cryptography (PBKDF2 du code PIN) |
| Fichiers | file_picker (enregistrer, choisir), share_plus, pdf |
| Langue | Français uniquement (`lib/l10n/app_fr.arb`) |

## Organisation du code

```
lib/
  app/            routes, thème, coquille des onglets
  core/           base, argent, dates, formats, erreurs, widgets partagés
  features/<x>/
    domain/       règles pures, sans Flutter ni base (testées en unitaire)
    data/         accès base, fichiers, plateforme
    presentation/ écrans, providers, contrôleurs
```

Règle : les calculs (soldes, budgets, prévisions, simulations, suggestions,
notifications…) vivent dans `domain/`, sous forme de fonctions pures. Les
écrans et le Copilote appellent **les mêmes** calculs : un chiffre affiché
est le même partout.

## Base de données

- Fichier `app_database.sqlite` dans les documents de l'application,
  chiffré ; clé aléatoire de 32 octets générée au premier lancement et
  gardée dans le coffre sécurisé. Contrôle au démarrage : refus d'ouvrir si
  le moteur n'est pas SQLite3MultipleCiphers (sinon `PRAGMA key` serait
  ignoré et la base écrite en clair).
- Montants stockés en entiers (FCFA), dates en millisecondes UTC.
- Schéma actuel : **v8**. Chaque version a son schéma figé
  (`drift_schemas/`) et une étape de migration testée depuis chaque version
  antérieure (`test/drift/`).

| Version | Ajout |
|---|---|
| v2 | Comptes |
| v3 | Catégories (par défaut) et opérations |
| v4 | Catégories personnalisées, masquage |
| v5 | Budgets |
| v6 | Opérations récurrentes |
| v7 | Objectifs d'épargne et mouvements |
| v8 | Historique du Copilote |

## Préférences hors base (shared_preferences)

Thème, masquage des montants, début du mois budgétaire, suggestions,
interrupteurs de notifications, préférence « charger l'IA au démarrage »,
date et taille de la dernière sauvegarde. Rien de financier.

Le coffre sécurisé contient aussi : empreinte du code PIN, réglages du
verrouillage, compteur d'erreurs.

## Code natif

Deux canaux de plateforme, même contrat sur Android (Kotlin, `MainActivity`)
et iOS (Swift, `AppDelegate`) :

- `finance_app/device` : `info` (version du système, 64 bits, mémoire
  totale et disponible, stockage libre, connexion facturée),
  `requestNotifications`, `setSecure` (Android : FLAG_SECURE).
- `finance_app/speech` (+ `.../events`) : dictée **sur l'appareil**
  (Android `createOnDeviceSpeechRecognizer`, iOS `SFSpeechRecognizer` avec
  `requiresOnDeviceRecognition`). Événements `ready`, `level`, `partial`,
  `final`, `error` (codes d'erreur Android, reproduits sur iOS).

## Plateformes

| | Android | iOS |
|---|---|---|
| Identifiant | `com.finao.app` | `com.finao.app` |
| Minimum | Android 7 (API 24) ; IA : Android 11 | iOS 15 |
| IA (Gemma) | CPU, 64 bits, ≥ 6 Go de mémoire | GPU Metal (testé sur iPhone 12 Pro Max) |
| Dictée | Reconnaissance Android sur l'appareil | SFSpeechRecognizer sur l'appareil |
| Masquage des applications récentes | Oui (verrouillage actif) | Non disponible |
| Autorisations mémoire étendue | — | Retirées (compte Apple gratuit) |

Android compile avec le SDK 37 (exigé par les notifications), thème de
démarrage AppCompat (exigé par la biométrie), activité
`FlutterFragmentActivity`.

## Démarrage

`main` lit le début du mois budgétaire **avant** le premier écran (aucun
total calculé sur le mauvais mois), puis l'application démarre sous la
« porte » de verrouillage. Au lancement : suivi du modèle IA, planification
des notifications, enregistrement automatique des échéances récurrentes
sans confirmation.

## Tests

`flutter test` : environ 260 tests (unitaires, widgets, migrations), sur
base en mémoire ou en fichier chiffré, avec faux Gemma, faux coffre et
préférences en mémoire (`test/flutter_test_config.dart`). Les tests passent
deux fois de suite avant chaque commit.
