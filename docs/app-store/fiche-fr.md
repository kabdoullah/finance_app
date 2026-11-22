# Fiche App Store — Finao (français)

## Nom (30 max)
Finao : budget et dépenses

## Sous-titre (30 max)
Ton argent en FCFA, hors ligne

## Texte promotionnel (170 max, modifiable sans nouvelle version)
Note une dépense en une phrase ou à la voix, surveille tes budgets et demande au Copilote combien tu peux encore dépenser. Tes données restent sur ton iPhone.

## Mots-clés (100 max, virgules sans espace)
épargne,comptes,mobile money,prévision,objectif,assistant,IA,dictée,relevé,CFA,gestion,banque

## Description (4000 max)
Finao t'aide à savoir où va ton argent, à tenir ton budget et à mettre de côté, en FCFA et sans connexion. Pas de compte à créer, pas de serveur : tout reste sur ton iPhone.

NOTE TES OPÉRATIONS EN QUELQUES SECONDES
• Écris ou dicte simplement « Déjeuner 2 500 et taxi 1 000 » : Finao remplit les montants, les catégories et le compte, tu vérifies, tu enregistres.
• Dépenses, revenus et transferts entre tes comptes (banque, espèces, mobile money…). Un transfert n'est jamais compté comme une dépense.
• Catégories et sous-catégories adaptées à la vie courante, modifiables.

GARDE LE CONTRÔLE DE TON MOIS
• Budgets par catégorie ou pour toutes tes dépenses, avec une alerte avant de dépasser.
• Opérations récurrentes (loyer, abonnement, salaire) enregistrées pour toi ou à confirmer.
• Prévision de ton solde jusqu'à la fin du mois et simulation d'un achat avant de te décider.

ÉPARGNE AVEC UN OBJECTIF
• Crée tes objectifs (fonds d'urgence, voyage, téléphone…) et réserve de l'argent sur tes comptes.
• Finao te dit combien mettre de côté chaque mois pour tenir ta date.

LE COPILOTE, TON ASSISTANT FINANCIER
• Pose tes questions en français : « Combien j'ai dépensé cette semaine ? », « Est-ce que je peux acheter un téléphone à 150 000 ? »
• Les chiffres sont calculés par l'application, l'IA les explique sans en inventer.
• Le modèle d'IA fonctionne directement sur ton iPhone, même en mode avion. Il se télécharge une seule fois (environ 2,5 Go, en Wi-Fi de préférence) et demande un iPhone récent avec au moins 6 Go de mémoire. Sans lui, toutes les autres fonctions restent disponibles.

TES DONNÉES T'APPARTIENNENT
• Base de données chiffrée sur ton iPhone, aucune donnée envoyée sur Internet.
• Verrouillage par code et Face ID, montants masquables d'un toucher.
• Sauvegarde chiffrée par mot de passe, à ranger où tu veux, et restauration sur un autre iPhone ou un Android.
• Export de tes opérations en CSV et relevé mensuel en PDF.

Finao est gratuit, sans publicité et sans abonnement.

## Notes pour la vérification d'Apple (App Review Information > Notes)
Finao works fully offline and requires no account or sign-in, so no demo account is needed. The app is in French.

How to test:
1. On first launch, add an account (e.g. "Espèces", balance 50 000).
2. Add an expense with the "+" button, or type "taxi 1000" in quick entry.
3. The Budgets and Prévisions (forecast) tabs use the data you entered.

Optional AI assistant ("Copilote", Assistant tab): it runs Google's Gemma model on-device. It is only offered on iPhones with at least 6 GB of RAM. In Settings > Assistant IA, the user can download the model once (about 2.5 GB) from Hugging Face. This is the only network request the app makes; no user data is sent. The increased-memory-limit and extended-virtual-addressing entitlements are required to load this model.

Microphone and speech recognition are used only for on-device dictation of transactions (SFSpeechRecognizer with requiresOnDeviceRecognition = true). Face ID is optional, to unlock the app.

## Champs App Store Connect
- Catégorie principale : Finance ; secondaire : Productivité
- Prix : Gratuit
- URL d'assistance : https://kabdoullah.github.io/finance_app/support/
- URL de la politique de confidentialité : https://kabdoullah.github.io/finance_app/confidentialite/
- Confidentialité de l'app : « Données non collectées »
- Classification par âge : « Aucun » à toutes les questions → 4+
- Copyright : « 2026 » suivi du nom du titulaire des droits
- Chiffrement (si la question est posée malgré la clé de l'Info.plist) : chiffrement standard (base SQLite chiffrée, sauvegardes, PBKDF2) utilisé seulement pour protéger les données de l'utilisateur, ce qui n'est pas la fonction principale de l'app → exemptée (catégorie 5, partie 2, note 4).
