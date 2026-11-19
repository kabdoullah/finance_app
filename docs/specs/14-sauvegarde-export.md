# 14 — Sauvegarde, restauration et export

## Sauvegarde
- Protégée par un **mot de passe propre à la sauvegarde** (8 caractères au
  moins, saisi deux fois, irrécupérable, jamais enregistré).
- Contenu : copie complète de la base (opérations, comptes, budgets,
  objectifs, récurrentes, catégories, historique du Copilote), **rechiffrée
  avec le mot de passe** ; date et version du schéma incluses. Les réglages
  du téléphone (thème, code PIN, notifications) n'en font pas partie.
- Fichier `finao-AAAA-MM-JJ.finao`, enregistré où l'utilisateur veut
  (sélecteur du système, Google Drive compris).
- Paramètres : « Aujourd'hui à 10:24 · 2,4 Mo, chiffrée » ; échec signalé
  (« Espace de stockage insuffisant… ») avec « Réessayer ».
- Pas de sauvegarde automatique ; rappel mensuel par notification.

## Restauration
1. Choix du fichier, puis du mot de passe.
2. Vérification : mot de passe faux ou fichier quelconque → « Mot de passe
   incorrect, ou ce fichier n'est pas une sauvegarde. » ; sauvegarde d'une
   version plus récente → refus (« Mets l'application à jour »).
3. Confirmation : « Tes données actuelles seront remplacées par celles du
   14 nov. à 21:14… ».
4. **Sans perte** : la base actuelle est mise de côté, la sauvegarde
   (rechiffrée avec la clé du téléphone) la remplace et s'ouvre (migrations
   comprises) ; en cas d'échec, les données actuelles reviennent
   automatiquement. Aucun fichier temporaire laissé.

Une sauvegarde faite sur Android se restaure sur iPhone et inversement.

## Export (fichiers non chiffrés, avec avertissement)
- **CSV** de toutes les opérations : séparateur « ; », UTF-8 avec BOM
  (Excel en français), montants entiers signés (dépenses négatives), dates
  « AAAA-MM-JJ HH:MM » ; colonnes Date, Type, Montant, Catégorie,
  Sous-catégorie, Compte, Vers le compte, Description, Saisie.
- **Relevé PDF** d'un mois budgétaire (12 derniers) : revenus, dépenses et
  solde du mois (transferts exclus), répartition des dépenses, tableau des
  opérations, numéros de page ; police Manrope.
- « Enregistrer » (sélecteur du système) ou « Partager » (menu de partage).
  Mois sans opération : « Aucune opération à exporter. »
