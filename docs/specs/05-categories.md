# 05 — Catégories

## Catégories par défaut (adaptées à la Côte d'Ivoire)
**Dépenses** : Alimentation (Marché, Restaurant, Boulangerie), Transport
(Taxi, Wôrô-wôrô, Gbaka, Carburant), Logement (Loyer, Entretien), Factures
(Électricité, Eau, Internet, Crédit téléphone), Loisirs (Sorties,
Abonnements), Santé (Pharmacie, Consultation), Famille, Tontine, Éducation,
Habillement, Autre.

**Revenus** : Salaire, Missions (Freelance, Consulting), Vente, Argent reçu
(Famille, Remboursement), Autre.

Leurs identifiants (`exp.food`, `exp.transport.taxi`…) sont stables : les
opérations y font référence.

## Règles
- Deux niveaux : catégorie principale et sous-catégories.
- Nom : 40 caractères au plus, unique parmi ses sœurs.
- Une sous-catégorie reprend l'icône de sa catégorie parente.
- **Prédéfinie** : peut seulement être masquée (et réaffichée).
- **Personnalisée** : renommable, masquable, supprimable ; ses opérations
  passent alors dans « Autre ».
- **« Autre »** : catégorie de repli, jamais masquée ni supprimée.
- **Masquée** : n'est plus proposée à la saisie, reste sur les opérations
  existantes.
