import 'package:drift/native.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/goals/data/goals_repository.dart';
import 'package:finance_app/features/goals/domain/goal_draft.dart';
import 'package:finance_app/features/goals/domain/savings_goal.dart';
import 'package:finance_app/features/transactions/data/transactions_repository.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/features/transactions/domain/transaction_draft.dart';
import 'package:flutter_test/flutter_test.dart';

SavingsGoal _goal({
  int target = 150000,
  int saved = 60000,
  DateTime? targetDate,
  DateTime? createdAt,
}) => SavingsGoal(
  id: 'g',
  name: 'Téléphone',
  iconKey: 'phone',
  target: Money(target),
  saved: Money(saved),
  targetDate: targetDate,
  createdAt: createdAt ?? DateTime(2026, 9),
);

void main() {
  group('SavingsGoal', () {
    final now = DateTime(2026, 11, 15, 9);

    test('effort : reste ÷ mois restants, arrondi à la centaine', () {
      // 90 000 restants, 77 jours ≈ 2,53 mois → 35 600 ; 11 semaines → 8 200.
      final goal = _goal(targetDate: DateTime(2027, 1, 31));
      expect(goal.left, const Money(90000));
      expect(goal.perMonth(now), const Money(35600));
      expect(goal.perWeek(now), const Money(8200));
    });

    test('moins d’un mois : tout le reste ; date dépassée : rien', () {
      expect(
        _goal(targetDate: DateTime(2026, 11, 30)).perMonth(now),
        const Money(90000),
      );
      final overdue = _goal(targetDate: DateTime(2026, 11, 10));
      expect(overdue.perMonth(now), isNull);
      expect(overdue.isOverdue(now), isTrue);
    });

    test('repousser : première fin de mois où l’effort tient le rythme', () {
      final goal = _goal(targetDate: DateTime(2027, 1, 31));
      // 90 000 restants, rythme de 13 300 par mois : fin mai demanderait
      // ≈ 14 000, fin juin ≈ 12 100.
      expect(goal.postponeFor(now, const Money(13300)), (
        DateTime(2027, 6, 30),
        const Money(12100),
      ));
      expect(goal.postponeFor(now, Money.zero), isNull);
      expect(_goal(saved: 0).postponeFor(now, const Money(13300)), isNull);
    });

    test('en retard sur le plan linéaire création → date cible', () {
      // Du 1er sept. au 1er janv. (122 j) ; au 15 nov. (75 j) on attend
      // ≈ 61,5 % de 100 000.
      DateTime target() => DateTime(2027);
      expect(
        _goal(target: 100000, saved: 60000, targetDate: target()).isLate(now),
        isTrue,
      );
      expect(
        _goal(target: 100000, saved: 62000, targetDate: target()).isLate(now),
        isFalse,
      );
      // Sans date ou atteint : jamais en retard.
      expect(_goal(saved: 0).isLate(now), isFalse);
      expect(_goal(saved: 150000, targetDate: target()).isLate(now), isFalse);
    });
  });

  group('GoalsRepository', () {
    late AppDatabase db;
    final now = DateTime(2026, 11, 15, 9);
    late GoalsRepository goals;
    late Account wave;
    late Account bank;

    T ok<T>(Result<T> result) => switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => fail('Échec inattendu : $failure'),
    };

    Set<Enum> errorsOf(Result<Object?> result) => switch (result) {
      Err(failure: ValidationFailure(:final errors)) => errors,
      _ => fail('Échec de validation attendu, obtenu : $result'),
    };

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final accounts = AccountsRepository(db, () => now);
      goals = GoalsRepository(db, () => now, accounts);
      Future<Account> account(String name, int balance) async => ok(
        await accounts.create(
          AccountDraft(
            type: AccountType.mobileMoney,
            name: name,
            openingBalance: Money(balance),
          ),
        ),
      );
      wave = await account('Wave', 42000);
      bank = await account('Ecobank', 300000);
    });
    tearDown(() => db.close());

    Future<SavingsGoal> create(String name) async => ok(
      await goals.create(
        GoalDraft(
          name: name,
          target: const Money(150000),
          iconKey: 'phone',
          targetDate: DateTime(2027, 1, 31),
        ),
      ),
    );

    test('la date cible doit être après aujourd’hui', () async {
      expect(
        errorsOf(
          await goals.create(
            GoalDraft(
              name: 'Moto',
              target: const Money(1000),
              iconKey: 'motorcycle',
              targetDate: DateTime(2026, 11, 15),
            ),
          ),
        ),
        {GoalFieldError.dateInPast},
      );
    });

    test('contribution plafonnée au disponible du compte', () async {
      final phone = await create('Téléphone');
      final tabaski = await create('Tabaski');

      ok(await goals.contribute(phone.id, wave.id, const Money(30000)));
      // Wave : 42 000 − 30 000 déjà réservés = 12 000 disponibles.
      expect(await goals.availableOn(wave.id), const Money(12000));
      expect(
        errorsOf(
          await goals.contribute(tabaski.id, wave.id, const Money(15000)),
        ),
        {GoalMovementError.amountTooLarge},
      );
      final updated = ok(
        await goals.contribute(tabaski.id, wave.id, const Money(12000)),
      );
      expect(updated.saved, const Money(12000));
    });

    test('retrait plafonné à la réserve de l’objectif sur ce compte', () async {
      final phone = await create('Téléphone');
      ok(await goals.contribute(phone.id, wave.id, const Money(20000)));
      ok(await goals.contribute(phone.id, bank.id, const Money(40000)));

      expect(
        errorsOf(await goals.withdraw(phone.id, wave.id, const Money(25000))),
        {GoalMovementError.amountTooLarge},
      );
      final after = ok(
        await goals.withdraw(phone.id, wave.id, const Money(20000)),
      );
      expect(after.saved, const Money(40000));
      expect(await goals.watchReservedByAccount(goalId: phone.id).first, {
        bank.id: const Money(40000),
      });
      final history = await goals.watchMovements(phone.id).first;
      expect(history, hasLength(3));
      expect(history.map((m) => m.signed.value).toSet(), {
        -20000,
        40000,
        20000,
      });
    });

    test('supprimer l’objectif libère ses réserves', () async {
      final phone = await create('Téléphone');
      ok(await goals.contribute(phone.id, wave.id, const Money(30000)));
      ok(await goals.delete(phone.id));
      expect(await goals.availableOn(wave.id), const Money(42000));
      expect(await goals.watchAll().first, isEmpty);
    });

    test('dépenses moyennes : 3 mois complets, rien sous 30 jours', () async {
      final transactions = TransactionsRepository(db, () => now);
      Future<void> expense(int amount, DateTime at) async => ok(
        await transactions.create(
          TransactionDraft(
            kind: TransactionKind.expense,
            amount: Money(amount),
            occurredAt: at,
            accountId: bank.id,
            categoryId: 'exp.food',
          ),
        ),
      );
      await expense(5000, DateTime(2026, 10, 20));
      // Première opération il y a 26 jours : trop peu d'historique.
      expect(await goals.averageMonthlyExpenses(), isNull);

      await expense(90000, DateTime(2026, 8, 10));
      await expense(55000, DateTime(2026, 9, 10));
      await expense(99999, DateTime(2026, 11, 2)); // mois en cours : ignoré
      // (90 000 + 55 000 + 5 000) ÷ 3 = 50 000.
      expect(await goals.averageMonthlyExpenses(), const Money(50000));
    });

    test(
      'rythme : rien avant 30 jours, puis moyenne sur les mois écoulés',
      () async {
        final phone = await create('Téléphone');
        ok(await goals.contribute(phone.id, bank.id, const Money(30000)));
        expect(await goals.averageMonthlyContribution(phone.id), isNull);

        final later = GoalsRepository(
          db,
          () => now.add(const Duration(days: 45)),
          AccountsRepository(db, () => now),
        );
        // 30 000 en 45 jours ≈ 1,48 mois → ≈ 20 292 par mois.
        expect(
          await later.averageMonthlyContribution(phone.id),
          const Money(20292),
        );
      },
    );

    test('il te reste en moyenne : revenus − dépenses sur 3 mois', () async {
      expect(await goals.averageMonthlySurplus(), isNull);
      final transactions = TransactionsRepository(db, () => now);
      for (final (kind, amount, month) in [
        (TransactionKind.income, 380000, 8),
        (TransactionKind.income, 380000, 9),
        (TransactionKind.expense, 290000, 10),
        // Mois en cours : ignoré.
        (TransactionKind.expense, 99999, 11),
      ]) {
        ok(
          await transactions.create(
            TransactionDraft(
              kind: kind,
              amount: Money(amount),
              occurredAt: DateTime(2026, month, 10),
              accountId: bank.id,
              categoryId: kind == TransactionKind.income
                  ? 'inc.salary'
                  : 'exp.housing',
            ),
          ),
        );
      }
      // (760 000 − 290 000) ÷ 3 = 156 666.
      expect(await goals.averageMonthlySurplus(), const Money(156666));
    });
  });
}
