import 'package:drift/drift.dart';

/// Catégories proposées au premier lancement (maquette Catégories, adaptée à
/// la Côte d'Ivoire). Les identifiants sont stables : ils ne doivent jamais
/// changer, les opérations y font référence.
///
/// Insérées par la migration v2 → v3 et à la création d'une base neuve.
const _expense = [
  (
    'exp.food',
    'Alimentation',
    'basket',
    [
      ('exp.food.market', 'Marché'),
      ('exp.food.restaurant', 'Restaurant'),
      ('exp.food.bakery', 'Boulangerie'),
    ],
  ),
  (
    'exp.transport',
    'Transport',
    'taxi',
    [
      ('exp.transport.taxi', 'Taxi'),
      ('exp.transport.woro', 'Wôrô-wôrô'),
      ('exp.transport.gbaka', 'Gbaka'),
      ('exp.transport.fuel', 'Carburant'),
    ],
  ),
  (
    'exp.housing',
    'Logement',
    'house-line',
    [('exp.housing.rent', 'Loyer'), ('exp.housing.upkeep', 'Entretien')],
  ),
  (
    'exp.bills',
    'Factures',
    'receipt',
    [
      ('exp.bills.electricity', 'Électricité'),
      ('exp.bills.water', 'Eau'),
      ('exp.bills.internet', 'Internet'),
      ('exp.bills.airtime', 'Crédit téléphone'),
    ],
  ),
  (
    'exp.leisure',
    'Loisirs',
    'ticket',
    [
      ('exp.leisure.outings', 'Sorties'),
      ('exp.leisure.subscriptions', 'Abonnements'),
    ],
  ),
  (
    'exp.health',
    'Santé',
    'heartbeat',
    [
      ('exp.health.pharmacy', 'Pharmacie'),
      ('exp.health.consultation', 'Consultation'),
    ],
  ),
  ('exp.family', 'Famille', 'users', <(String, String)>[]),
  ('exp.tontine', 'Tontine', 'hand-coins', <(String, String)>[]),
  ('exp.education', 'Éducation', 'graduation-cap', <(String, String)>[]),
  ('exp.clothing', 'Habillement', 't-shirt', <(String, String)>[]),
  ('exp.other', 'Autre', 'dots-three', <(String, String)>[]),
];

const _income = [
  ('inc.salary', 'Salaire', 'money', <(String, String)>[]),
  (
    'inc.missions',
    'Missions',
    'hand-coins',
    [
      ('inc.missions.freelance', 'Freelance'),
      ('inc.missions.consulting', 'Consulting'),
    ],
  ),
  ('inc.sale', 'Vente', 'tag', <(String, String)>[]),
  (
    'inc.received',
    'Argent reçu',
    'arrow-down-left',
    [
      ('inc.received.family', 'Famille'),
      ('inc.received.refund', 'Remboursement'),
    ],
  ),
  ('inc.other', 'Autre', 'dots-three', <(String, String)>[]),
];

/// Insère les catégories par défaut. SQL brut : indépendant des classes
/// générées, donc stable dans une migration.
Future<void> insertDefaultCategories(DatabaseConnectionUser db, int nowMs) =>
    db.batch((batch) {
      var order = 0;
      void insert(
        String id,
        String name,
        String kind,
        String icon,
        String? parentId,
      ) => batch.customStatement(
        'INSERT INTO categories '
        '(id, name, kind, icon, parent_id, sort_order, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [id, name, kind, icon, parentId, order++, nowMs, nowMs],
      );

      for (final (kind, groups) in [
        ('expense', _expense),
        ('income', _income),
      ]) {
        for (final (id, name, icon, children) in groups) {
          insert(id, name, kind, icon, null);
          for (final (childId, childName) in children) {
            insert(childId, childName, kind, icon, id);
          }
        }
      }
    });
