import 'package:drift/native.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/core/time/month.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/categories/data/categories_repository.dart';
import 'package:finance_app/features/categories/domain/category.dart';
import 'package:finance_app/features/transactions/data/transactions_repository.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/features/transactions/domain/transaction_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AccountsRepository accounts;
  late TransactionsRepository transactions;
  late Account wave;
  late Account ecobank;
  var now = DateTime.utc(2026, 11, 15, 9);

  T ok<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Échec inattendu : $failure'),
  };

  Set<TransactionFieldError> errorsOf(Result<Object?> result) =>
      switch (result) {
        Err(failure: ValidationFailure<TransactionFieldError>(:final errors)) =>
          errors,
        _ => fail('Échec de validation attendu, obtenu : $result'),
      };

  TransactionDraft expense(int amount, {String category = 'exp.transport'}) =>
      TransactionDraft(
        kind: TransactionKind.expense,
        amount: Money(amount),
        occurredAt: now,
        accountId: wave.id,
        categoryId: category,
      );

  Future<Money> balanceOf(Account account) async =>
      (await accounts.watchById(account.id).first)!.balance;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 11, 15, 9);
    var nextId = 0;
    accounts = AccountsRepository(db, () => now, newId: () => 'a${nextId++}');
    transactions = TransactionsRepository(
      db,
      () => now,
      newId: () => 't${nextId++}',
    );
    wave = ok(
      await accounts.create(
        const AccountDraft(
          type: AccountType.mobileMoney,
          name: 'Wave',
          openingBalance: Money(42000),
        ),
      ),
    );
    ecobank = ok(
      await accounts.create(
        const AccountDraft(
          type: AccountType.bank,
          name: 'Ecobank',
          openingBalance: Money(126000),
        ),
      ),
    );
  });
  tearDown(() => db.close());

  test('les catégories par défaut sont créées avec la base', () async {
    final groups = await CategoriesRepository(
      db,
      () => now,
    ).watchGroups(CategoryKind.expense).first;

    final transport = groups.firstWhere((g) => g.category.name == 'Transport');
    expect(transport.children.map((c) => c.name), contains('Wôrô-wôrô'));
  });

  test('une dépense diminue le solde ; un revenu l’augmente', () async {
    final taxi = ok(
      await transactions.create(
        expense(2500).copyWith(categoryId: 'exp.transport.taxi'),
      ),
    );
    ok(
      await transactions.create(
        TransactionDraft(
          kind: TransactionKind.income,
          amount: const Money(45000),
          occurredAt: now,
          accountId: wave.id,
          categoryId: 'inc.missions',
        ),
      ),
    );

    expect(taxi.category?.name, 'Taxi');
    expect(taxi.parentCategory?.name, 'Transport');
    expect(taxi.accountName, 'Wave');
    expect(await balanceOf(wave), const Money(42000 - 2500 + 45000));

    final updatedWave = (await accounts.watchById(wave.id).first)!;
    expect(updatedWave.operationCount, 2);
    expect(updatedWave.lastOperationAt, now);
  });

  test('un transfert déplace l’argent sans changer le total', () async {
    final transfer = ok(
      await transactions.create(
        TransactionDraft(
          kind: TransactionKind.transfer,
          amount: const Money(25000),
          occurredAt: now,
          accountId: ecobank.id,
          toAccountId: wave.id,
        ),
      ),
    );

    expect(transfer.toAccountName, 'Wave');
    expect(await balanceOf(ecobank), const Money(101000));
    expect(await balanceOf(wave), const Money(67000));
  });

  test('refuse un transfert vers le même compte et une catégorie du mauvais '
      'type', () async {
    expect(
      errorsOf(
        await transactions.create(
          TransactionDraft(
            kind: TransactionKind.transfer,
            amount: const Money(1000),
            occurredAt: now,
            accountId: wave.id,
            toAccountId: wave.id,
          ),
        ),
      ),
      {TransactionFieldError.sameAccount},
    );
    expect(
      errorsOf(await transactions.create(expense(1000, category: 'inc.salary'))),
      {TransactionFieldError.categoryInvalid},
    );
  });

  test('refuse une opération sur un compte archivé', () async {
    await accounts.archive(wave.id);

    expect(errorsOf(await transactions.create(expense(1000))), {
      TransactionFieldError.accountUnavailable,
    });
  });

  test('supprimer puis annuler restaure l’opération et le solde', () async {
    final taxi = ok(await transactions.create(expense(2500)));

    final deleted = ok(await transactions.delete(taxi.id));
    expect(await balanceOf(wave), const Money(42000));

    ok(await transactions.restore(deleted));
    expect(await balanceOf(wave), const Money(39500));
    expect((await transactions.watchById(taxi.id).first)?.amount, const Money(2500));
  });

  test('dupliquer crée une copie datée de maintenant', () async {
    final taxi = ok(await transactions.create(expense(2500)));
    now = DateTime.utc(2026, 11, 16, 8);

    final copy = ok(await transactions.duplicate(taxi.id));

    expect(copy.id, isNot(taxi.id));
    expect(copy.occurredAt, now);
    expect(await balanceOf(wave), const Money(37000));
  });

  test('modifier une opération recalcule le solde', () async {
    final taxi = ok(await transactions.create(expense(2500)));

    ok(await transactions.update(taxi.id, expense(3000)));

    expect(await balanceOf(wave), const Money(39000));
  });

  test('supprimer un compte supprime ses opérations', () async {
    ok(await transactions.create(expense(2500)));
    ok(
      await transactions.create(
        TransactionDraft(
          kind: TransactionKind.transfer,
          amount: const Money(1000),
          occurredAt: now,
          accountId: ecobank.id,
          toAccountId: wave.id,
        ),
      ),
    );

    await accounts.delete(wave.id);

    expect(await transactions.watchRecent(10).first, isEmpty);
    expect(await balanceOf(ecobank), const Money(126000));
  });

  test('liste du mois et dernier compte utilisé', () async {
    ok(await transactions.create(expense(2500)));
    // Saisie le 16 novembre d'une opération datée du 30 octobre.
    now = DateTime.utc(2026, 11, 16, 12);
    ok(
      await transactions.create(
        expense(1000).copyWith(
          accountId: ecobank.id,
          occurredAt: DateTime.utc(2026, 10, 30, 12),
        ),
      ),
    );

    final november = await transactions
        .watchMonth(const Month(2026, 11))
        .first;
    expect(november.map((t) => t.amount), [const Money(2500)]);
    // Dernière saisie (created_at), même si elle est datée d'octobre.
    expect(await transactions.lastUsedAccountId(), ecobank.id);
  });
}
