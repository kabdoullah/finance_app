# POC IA — rapport (18 novembre 2026)

Téléphone : Redmi Note 12 Pro+ 5G (Dimensity 1080, Mali-G68, 8 Go, Android 14).
Pile : `flutter_edge_ai` 2.6.0, `flutter_edge_ai_litertlm` 1.20.2,
`flutter_edge_ai_speech` 0.6.1, `record` 7.2.0, build release.
Modèle : `litert-community/gemma-4-E2B-it-litert-lm` / `gemma-4-E2B-it.litertlm`
(révision `b3ca0d2`, Apache-2.0, public). Données de test fictives.

## Téléchargement

2,47 Go installés en 239 s (Wi-Fi), service au premier plan, sans incident.

## Performances (invite de 30 mots, réponse de 4 phrases)

| Configuration | Chargement | 1er mot | Vitesse | RAM max |
|---|---|---|---|---|
| CPU | 6,3 s | 2,7 s | 7,5 jetons/s | 1,9 Go |
| GPU fp16 | 41,9 s | 1,5 s | 7,2 jetons/s | 2,3 Go |
| GPU fp32 | 40,0 s | 1,8 s | 6,4 jetons/s | 2,9 Go |

Français généré : correct, clair, naturel.
Sur ce téléphone, le GPU (OpenCL, Mali) ne génère pas plus vite et se charge
en ~40 s : **CPU retenu**. Le NPU MediaTek n'est pas pris en charge (MT6991
et MT6993 seulement).

## Appels d'outils (20 questions, CPU, température 0)

- 1er passage : 18/20 (90 %).
- Avec les sous-catégories dans la description de l'outil (taxi,
  wôrô-wôrô, gbaka, garba…) : **19/20 (95 %)**.
- Échec restant : « Quel budget je risque de dépasser ? » → réponse en texte
  sans appel d'outil.
- Réponses finales justes avec résultats fictifs : « Vous avez dépensé
  48 000 FCFA pour le wôrô-wôrô ce mois-ci. »
- **≈ 10 s par question** (nouvelle conversation à chaque fois : le modèle
  relit consigne et outils).

## Saisie rapide → JSON (20 phrases, CPU)

- 1er passage interrompu : le décodage contraint plante sur une valeur
  d'énumération avec espace (« Orange Money ») et la consigne poussait vers
  `transfer`.
- Avec des codes stables (`orange_money`, `food`…), des règles explicites
  et deux exemples : **96/100 champs (96 %)**.
- Erreurs : compte « none » remplacé par `cash` (3 fois) ; « envoi au
  village » classé `transfer` au lieu de `expense`.
- **≈ 10 s par saisie.**

## Voix (Whisper tiny, français, 6 essais)

Inutilisable : « taxi deux mille sur Wave » → « Taxi 2000 francs sur WIF » ;
« salaire trois cent quatre-vingt mille sur Ecobank » → « Sal est 2-3 000 » /
« Salais 200 000, je suis écho-bancre » ; « garba mille hier » → « Gaba mille
franiers ». 5 à 7,5 s pour 5 s d'audio.

## Critères

| Critère | Résultat | |
|---|---|---|
| Chargement < 15 s | 6,3 s | ✅ |
| 1er mot < 3 s | 2,7 s | ✅ |
| ≥ 8 jetons/s | 7,5 | ⚠️ |
| RAM < 3,5 Go | 1,9 Go | ✅ |
| Outils ≥ 85 % | 95 % | ✅ |
| Saisie JSON ≥ 85 % | 96 % | ✅ |
| Voix utilisable | non | ❌ |

## Leçons pour l'application

1. Énumérations : codes stables sans espace ni accent.
2. Donner les sous-catégories (vocabulaire ivoirien) dans les outils et
   consignes.
3. Le principal frein est la latence de ≈ 10 s par requête : garder une
   session ouverte, raccourcir les consignes, ne pas utiliser Gemma pour la
   saisie rapide courante.
4. La reconnaissance vocale doit venir d'ailleurs que Whisper tiny.
