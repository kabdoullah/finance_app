// Finao avec des données FICTIVES, pour les captures d'écran des stores.
//
//   flutter run -d <simulateur> -t tool/demo/main_demo.dart \
//     --dart-define=DEMO_ROUTE=/budgets
//
// DEMO_ROUTE (facultatif) : écran ouvert après le splash, ex. /transactions,
// /budgets/goals, /forecast, /quick-entry?mode=text&text=Déjeuner%202500.
//
// Base en mémoire, recréée à chaque lancement : ni Keychain ni vraie donnée
// touchés. Ce fichier n'est pas importé par lib/ : il n'est jamais dans
// l'application publiée.
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finance_app/app/app.dart';
import 'package:finance_app/app/router.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/database/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase(NativeDatabase.memory());
  await seedDemoData(db, DateTime.now());
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  runApp(
    UncontrolledProviderScope(container: container, child: const FinanceApp()),
  );
  const route = String.fromEnvironment('DEMO_ROUTE');
  if (route.isNotEmpty) {
    // Après le splash (≈ 2,1 s).
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    container.read(appRouterProvider).go(route);
    debugPrint('DEMO_ROUTE $route');
  }
}

const _bank = 'demo-bank';
const _mobile = 'demo-mobile';
const _cash = 'demo-cash';
const _savings = 'demo-savings';

/// Deux mois et demi d'une vie fictive à Abidjan, datés par rapport à [now].
Future<void> seedDemoData(AppDatabase db, DateTime now) async {
  final random = Random(42);
  final start = DateTime(now.year, now.month - 2);
  final created = _ms(start);
  var seq = 0;
  String id(String prefix) => 'demo-$prefix-${seq++}';

  await db.batch((b) {
    b.insertAll(db.accounts, [
      for (final (accountId, name, type, opening) in const [
        (_bank, 'Banque', 'bank', 180000),
        (_mobile, 'Mobile money', 'mobile_money', 25000),
        (_cash, 'Espèces', 'cash', 15000),
        (_savings, 'Épargne', 'savings', 220000),
      ])
        AccountsCompanion.insert(
          id: accountId,
          name: name,
          type: type,
          openingBalance: opening,
          createdAt: created,
          updatedAt: created,
        ),
    ]);

    void add(
      DateTime at,
      String kind,
      int amount,
      String account, {
      String? category,
      String? to,
      String? label,
      String entry = 'manual',
    }) {
      if (at.isAfter(now)) return;
      b.insert(
        db.transactions,
        TransactionsCompanion.insert(
          id: id('tx'),
          kind: kind,
          amount: amount,
          accountId: account,
          toAccountId: Value(to),
          categoryId: Value(category),
          description: Value(label),
          occurredAt: _ms(at),
          entryMethod: Value(entry),
          createdAt: _ms(at),
          updatedAt: _ms(at),
        ),
      );
    }

    void expense(
      DateTime at,
      int amount,
      String account,
      String category, [
      String? label,
      String entry = 'manual',
    ]) => add(
      at,
      'expense',
      amount,
      account,
      category: category,
      label: label,
      entry: entry,
    );

    // Montant arrondi à 500 FCFA entre [min] et [max].
    int around(int min, int max) =>
        (min + random.nextInt(max - min + 1)) ~/ 500 * 500;

    for (var m = 0; m < 3; m++) {
      final month = DateTime(start.year, start.month + m);
      DateTime day(int d, [int hour = 12]) =>
          DateTime(month.year, month.month, d, hour, random.nextInt(60));

      add(
        day(1, 9),
        'income',
        450000,
        _bank,
        category: 'inc.salary',
        label: 'Salaire',
      );
      add(day(2, 10), 'transfer', 150000, _bank, to: _mobile);
      add(day(2, 11), 'transfer', 100000, _bank, to: _cash);
      expense(day(3, 10), 120000, _bank, 'exp.housing.rent', 'Loyer');
      expense(day(5, 19), 15000, _mobile, 'exp.bills.internet', 'Box internet');
      expense(day(6, 18), 20000, _mobile, 'exp.tontine', 'Tontine du bureau');
      expense(
        day(10, 17),
        around(16000, 21000),
        _mobile,
        'exp.bills.electricity',
        'Facture électricité',
      );
      expense(
        day(12, 17),
        around(5000, 7000),
        _mobile,
        'exp.bills.water',
        'Facture eau',
      );
      expense(day(14, 20), 25000, _mobile, 'exp.family', 'Maman');
      expense(
        day(16, 21),
        5000,
        _mobile,
        'exp.leisure.subscriptions',
        'Abonnement musique',
      );
      if (m == 1) {
        add(
          day(18, 15),
          'income',
          75000,
          _mobile,
          category: 'inc.missions.freelance',
          label: 'Site web client',
        );
        expense(day(21, 16), 4500, _cash, 'exp.health.pharmacy', 'Pharmacie');
        expense(day(25, 15), 18000, _bank, 'exp.clothing', 'Pagne');
      }

      for (var d = 1; d <= 31; d++) {
        if (DateTime(month.year, month.month, d).month != month.month) break;
        if (d % 3 == 1) {
          expense(
            day(d, 8),
            around(4000, 11000),
            _cash,
            'exp.food.market',
            'Marché',
            d % 2 == 0 ? 'voice' : 'manual',
          );
        }
        if (d % 2 == 0) {
          expense(
            day(d, 7),
            around(500, 2000),
            _cash,
            d % 4 == 0 ? 'exp.transport.woro' : 'exp.transport.taxi',
            null,
            d % 6 == 0 ? 'voice' : 'manual',
          );
        }
        if (d % 5 == 2) {
          expense(
            day(d, 13),
            around(2500, 5000),
            _mobile,
            'exp.food.restaurant',
            'Déjeuner',
            'text',
          );
        }
        if (d % 7 == 3) {
          expense(day(d, 9), 2000, _mobile, 'exp.bills.airtime');
        }
        if (d % 9 == 6) {
          expense(
            day(d, 21),
            around(8000, 14000),
            _mobile,
            'exp.leisure.outings',
            'Sortie entre amis',
          );
        }
        if (d % 8 == 4) {
          expense(day(d, 7), 1000, _cash, 'exp.food.bakery', 'Pain');
        }
      }
    }

    b.insertAll(db.budgets, [
      for (final (category, limit) in const [
        (null, 400000),
        ('exp.food', 90000),
        ('exp.transport', 25000),
        ('exp.leisure', 40000),
        ('exp.bills', 50000),
      ])
        BudgetsCompanion.insert(
          id: id('budget'),
          categoryId: Value(category),
          limitAmount: limit,
          alertPercent: 80,
          createdAt: created,
          updatedAt: created,
        ),
    ]);

    String date(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    DateTime next(int dayOfMonth) {
      final thisMonth = DateTime(now.year, now.month, dayOfMonth);
      return thisMonth.isAfter(now)
          ? thisMonth
          : DateTime(now.year, now.month + 1, dayOfMonth);
    }

    b.insertAll(db.recurringOperations, [
      for (final (kind, name, amount, category, account, due, ask) in [
        ('income', 'Salaire', 450000, 'inc.salary', _bank, next(1), false),
        ('expense', 'Loyer', 120000, 'exp.housing.rent', _bank, next(3), false),
        (
          'expense',
          'Box internet',
          15000,
          'exp.bills.internet',
          _mobile,
          next(5),
          false,
        ),
        (
          'expense',
          'Tontine du bureau',
          20000,
          'exp.tontine',
          _mobile,
          next(6),
          true,
        ),
      ])
        RecurringOperationsCompanion.insert(
          id: id('recurring'),
          kind: kind,
          name: name,
          amount: amount,
          categoryId: category,
          accountId: account,
          frequency: 'month',
          startDate: date(start),
          nextDueDate: Value(date(due)),
          askBeforeRecording: Value(ask),
          createdAt: created,
          updatedAt: created,
        ),
    ]);

    for (final (name, icon, target, months, account, saved) in const [
      (
        "Fonds d'urgence",
        'umbrella',
        600000,
        8,
        _savings,
        [100000, 50000, 30000],
      ),
      ('Nouveau téléphone', 'phone', 180000, 3, _savings, [40000, 25000]),
      ('Vacances à Assinie', 'airplane', 150000, 5, _mobile, [10000]),
    ]) {
      final goalId = id('goal');
      b.insert(
        db.savingsGoals,
        SavingsGoalsCompanion.insert(
          id: goalId,
          name: name,
          iconKey: icon,
          targetAmount: target,
          targetDate: Value(date(DateTime(now.year, now.month + months, 28))),
          createdAt: created,
          updatedAt: created,
        ),
      );
      for (var i = 0; i < saved.length; i++) {
        final at = DateTime(start.year, start.month + i, 4, 20);
        b.insert(
          db.goalMovements,
          GoalMovementsCompanion.insert(
            id: id('move'),
            goalId: goalId,
            kind: 'contribution',
            amount: saved[i],
            accountId: account,
            occurredAt: _ms(at),
            createdAt: _ms(at),
          ),
        );
      }
    }
  });
}

int _ms(DateTime date) => date.toUtc().millisecondsSinceEpoch;
