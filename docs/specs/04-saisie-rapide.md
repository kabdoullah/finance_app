# 04 — Saisie rapide (texte et dictée)

Bouton « Ajouter » › **Dicter** ou **Écrire** : une phrase peut contenir
plusieurs opérations (« Déjeuner 2 500 et taxi 1 000 avec Wave »).

## Étapes
1. **Écoute** (dictée) ou **saisie du texte**.
2. **Analyse** par l'analyseur de l'application (sans IA) : montants
   (« 2 500 », « 2500 », « 25 mille », « 1,5 million »), type, catégorie
   et sous-catégorie par mots-clés, compte cité, date (« ce matin »,
   « hier », « avant-hier »), découpage en plusieurs opérations,
   transferts « de X vers Y ».
3. **Complétion par Gemma** (si le modèle est chargé et qu'il reste des
   champs incertains) : Gemma propose catégorie, compte, type ou montant
   **uniquement pour les champs « À vérifier »**, qui gardent leur marque.
   Bouton « Passer » ; 30 s au plus par opération ; en cas d'erreur, le
   résultat de l'analyseur est conservé. Gemma ne touche pas aux dates.
4. **Récapitulatif** : chaque opération est modifiable (type, montant,
   description, catégorie, compte, date), ajoutable ou retirable ; champs
   incertains marqués « À vérifier ». Rien n'est enregistré avant
   « Enregistrer ».

Bandeau du récapitulatif : rien si Gemma est chargé ; « Analyse
simplifiée… » si l'IA n'est pas possible sur le téléphone ; « Assistant IA
indisponible » avec « Gérer le modèle IA » si l'IA est possible mais pas
chargée.

## Dictée
- **Toujours sur l'appareil**, jamais via un serveur (Android et iOS).
- Fin automatique après environ 1,5 s de silence ; abandon après 6 s sans
  parole (« Je n'ai rien entendu »).
- Jauge animée selon le volume du micro ; texte affiché au fil de la parole.
- Français hors connexion absent : écran « Installe le français pour
  dicter » avec les étapes du système (Android : installation proposée,
  puis paramètres de Gboard ; iOS : Réglages › Général › Clavier › Dictée).
- Micro refusé : passage à l'écriture avec un message.

## Origine enregistrée
« Dictée » ou « Texte » selon le mode ; « Texte » aussi pour une opération
préparée par le Copilote.
