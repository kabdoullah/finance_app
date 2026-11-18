import 'package:drift/native.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/budgets/data/budgets_repository.dart';
import 'package:finance_app/features/budgets/domain/budget.dart';
import 'package:finance_app/features/budgets/domain/budget_draft.dart';
import 'package:finance_app/features/categories/domain/category.dart';
import 'package:finance_app/features/transactions/data/transactions_repository.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/features/transactions/domain/transaction_draft.dart';
import 'package:flutter_test/flutter_test.dart';

const _food = Category(
  id: 'exp.food',
  name: 'Alimentation',
  kind: CategoryKind.expense,
  iconKey: 'basket',
);

Budget _budget(int limit, {int alert = 80, Category? category = _food}) =>
    Budget(
      id: 'b',
      limit: Money(limit),
      alertPercent: alert,
      category: category,
    );

void main() {
  group('BudgetStatus', () {
    test('niveaux : ok, ambre au seuil, Payé à 100 %, dépassé', () {
      BudgetLevel level(int spent) =>
          BudgetStatus.of(_budget(100000), Money(spent)).level;

      expect(level(79999), BudgetLevel.ok);
      expect(level(80000), BudgetLevel.warning);
      expect(level(100000), BudgetLevel.reached);
      expect(level(100001), BudgetLevel.exceeded);
    });

    test(
      'reste négatif et pourcentage au-delà de 100 en cas de dépassement',
      () {
        final status = BudgetStatus.of(_budget(45000), const Money(48000));

        expect(status.remaining, const Money(-3000));
        expect(status.percent, 106);
      },
    );
  });

  test('somme par jour arrondie à la centaine, 0 si épuisé', () {
    // Maquette : 31 600 FCFA sur 15 jours ≈ 2 100 FCFA par jour.
    expect(dailyAllowance(const Money(31600), 15), const Money(2100));
    expect(dailyAllowance(const Money(-3000), 15), Money.zero);
  });

  group('prévision de dépassement', () {
    BudgetStatus status(int spent) =>
        BudgetStatus.of(_budget(30000), Money(spent));

    test('au rythme moyen du mois', () {
      // 10 jours, 20 000 dépensés → 2 000 / jour ; reste 10 000 → le 6e
      // jour suivant franchit la limite : 16 nov.
      expect(
        projectedOverrun(status(20000), DateTime(2026, 11, 10, 9)),
        DateTime(2026, 11, 16),
      );
    });

    test('rien avant le 5, ni si déjà dépassé, ni après la fin du mois', () {
      expect(projectedOverrun(status(20000), DateTime(2026, 11, 4)), isNull);
      expect(projectedOverrun(status(31000), DateTime(2026, 11, 10)), isNull);
      // 1 000 en 10 jours → 100 / jour : dépassement bien après le 30.
      expect(projectedOverrun(status(1000), DateTime(2026, 11, 10)), isNull);
    });
  });

  group('BudgetDriver', () {
    const transport = Category(
      id: 'exp.transport',
      name: 'Transport',
      kind: CategoryKind.expense,
      iconKey: 'taxi',
    );
    Category sub(String id, String name) => Category(
      id: id,
      name: name,
      kind: CategoryKind.expense,
      iconKey: 'taxi',
      parentId: transport.id,
    );
    Transaction expense(int amount, Category category) => Transaction(
      id: '$amount',
      kind: TransactionKind.expense,
      amount: Money(amount),
      accountId: 'a',
      accountName: 'Wave',
      category: category,
      parentCategory: category.parentId == null ? null : transport,
      occurredAt: DateTime(2026, 11, 10),
      entryMethod: EntryMethod.manual,
    );
    final budget = _budget(30000, category: transport);

    test('la sous-catégorie qui pèse le plus', () {
      final taxi = sub('exp.transport.taxi', 'Taxi');
      final driver = BudgetDriver.of(budget, [
        expense(3000, taxi),
        expense(4000, taxi),
        expense(5000, sub('exp.transport.fuel', 'Carburant')),
        expense(2000, transport),
      ])!;

      expect(driver.category.name, 'Taxi');
      expect(driver.count, 2);
      expect(driver.total, const Money(7000));
    });

    test('rien si la catégorie principale elle-même pèse le plus', () {
      expect(
        BudgetDriver.of(budget, [
          expense(9000, transport),
          expense(3000, sub('exp.transport.taxi', 'Taxi')),
        ]),
        isNull,
      );
    });
  });

  group('BudgetsRepository', () {
    late AppDatabase db;
    late BudgetsRepository budgets;
    late TransactionsRepository transactions;
    late Account wave;
    final now = DateTime.utc(2026, 11, 17, 9);

    T ok<T>(Result<T> result) => switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => fail('Échec inattendu : $failure'),
    };

    Set<BudgetFieldError> errorsOf(Result<Object?> result) => switch (result) {
      Err(failure: ValidationFailure<BudgetFieldError>(:final errors)) =>
        errors,
      _ => fail('Échec de validation attendu, obtenu : $result'),
    };

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      budgets = BudgetsRepository(db, () => now);
      transactions = TransactionsRepository(db, () => now);
      wave = ok(
        await AccountsRepository(db, () => now).create(
          const AccountDraft(
            type: AccountType.mobileMoney,
            name: 'Wave',
            openingBalance: Money(500000),
          ),
        ),
      );
    });
    tearDown(() => db.close());

    test('un seul budget par catégorie et un seul budget global', () async {
      ok(
        await budgets.create(
          const BudgetDraft(limit: Money(120000), categoryId: 'exp.food'),
        ),
      );
      ok(await budgets.create(const BudgetDraft(limit: Money(300000))));

      expect(
        errorsOf(
          await budgets.create(
            const BudgetDraft(limit: Money(1000), categoryId: 'exp.food'),
          ),
        ),
        {BudgetFieldError.alreadyExists},
      );
      expect(
        errorsOf(await budgets.create(const BudgetDraft(limit: Money(1000)))),
        {BudgetFieldError.alreadyExists},
      );

      final all = await budgets.watchAll().first;
      expect(all.first.isGlobal, isTrue);
      expect(all.last.category?.name, 'Alimentation');
    });

    test('refuse une catégorie de revenus ou une sous-catégorie', () async {
      for (final id in ['inc.salary', 'exp.food.market']) {
        expect(
          errorsOf(
            await budgets.create(
              BudgetDraft(limit: const Money(1000), categoryId: id),
            ),
          ),
          {BudgetFieldError.categoryInvalid},
        );
      }
    });

    test(
      'moyenne des 3 derniers mois complets, sous-catégories comprises',
      () async {
        Future<void> expense(int amount, DateTime at, String category) async =>
            ok(
              await transactions.create(
                TransactionDraft(
                  kind: TransactionKind.expense,
                  amount: Money(amount),
                  occurredAt: at,
                  accountId: wave.id,
                  categoryId: category,
                ),
              ),
            );
        await expense(90000, DateTime.utc(2026, 8, 10), 'exp.food');
        await expense(60000, DateTime.utc(2026, 9, 10), 'exp.food.market');
        await expense(30000, DateTime.utc(2026, 10, 10), 'exp.food');
        // Hors période (mois en cours) et hors catégorie : ignorés.
        await expense(99999, DateTime.utc(2026, 11, 2), 'exp.food');
        await expense(50000, DateTime.utc(2026, 10, 5), 'exp.transport');

        expect(
          await budgets.averageMonthlySpending('exp.food'),
          const Money(60000),
        );
        expect(await budgets.averageMonthlySpending(null), const Money(76600));
      },
    );
  });
}
