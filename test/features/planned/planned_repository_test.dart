import 'package:drift/native.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/categories/data/categories_repository.dart';
import 'package:finance_app/features/categories/domain/category.dart';
import 'package:finance_app/features/categories/domain/category_draft.dart';
import 'package:finance_app/features/forecast/data/forecast_repository.dart';
import 'package:finance_app/features/planned/data/planned_repository.dart';
import 'package:finance_app/features/planned/domain/planned_draft.dart';
import 'package:finance_app/features/planned/domain/planned_expense.dart';
import 'package:finance_app/features/transactions/data/transactions_repository.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AccountsRepository accounts;
  late TransactionsRepository transactions;
  late PlannedRepository planned;
  late Account ecobank;
  // Scénario de la maquette Regles-Planifiees : création le 20 nov.
  var now = DateTime(2026, 11, 20, 10);

  T ok<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Échec inattendu : $failure'),
  };

  Set<PlannedFieldError> errorsOf(Result<Object?> result) => switch (result) {
    Err(failure: ValidationFailure<PlannedFieldError>(:final errors)) => errors,
    _ => fail('Échec de validation attendu, obtenu : $result'),
  };

  PlannedDraft scolarite({DateTime? due, String name = 'Scolarité'}) =>
      PlannedDraft(
        name: name,
        amount: const Money(150000),
        dueDate: due ?? DateTime(2026, 12, 15),
        categoryId: 'exp.education',
        accountId: ecobank.id,
        note: '2e trimestre',
      );

  Future<Money> balance() async =>
      (await accounts.watchById(ecobank.id).first)!.balance;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime(2026, 11, 20, 10);
    var nextId = 0;
    String id() => 'id${nextId++}';
    accounts = AccountsRepository(db, () => now, newId: id);
    transactions = TransactionsRepository(db, () => now, newId: id);
    planned = PlannedRepository(db, () => now, transactions, newId: id);
    ecobank = ok(
      await accounts.create(
        const AccountDraft(
          type: AccountType.bank,
          name: 'Ecobank',
          openingBalance: Money(217500),
        ),
      ),
    );
  });
  tearDown(() => db.close());

  test('A · créée : à payer, sans toucher au solde', () async {
    final expense = ok(await planned.create(scolarite()));

    expect(expense.name, 'Scolarité');
    expect(expense.dueDate, DateTime(2026, 12, 15));
    expect(expense.note, '2e trimestre');
    expect(expense.statusOn(now), PlannedStatus.planned);
    expect(await planned.watchAll().first, hasLength(1));
    expect(await balance(), const Money(217500));
  });

  test('la date prévue doit être après aujourd’hui', () async {
    expect(
      errorsOf(await planned.create(scolarite(due: DateTime(2026, 11, 20)))),
      {PlannedFieldError.dueNotInFuture},
    );
    expect(errorsOf(await planned.create(scolarite(name: '  '))), {
      PlannedFieldError.nameMissing,
    });
  });

  test(
    'C · date dépassée sans paiement : en retard, toujours à payer',
    () async {
      final expense = ok(await planned.create(scolarite()));
      now = DateTime(2026, 12, 16, 9);

      expect(expense.statusOn(now), PlannedStatus.late);
      expect(await planned.watchAll().first, hasLength(1));
      expect(await balance(), const Money(217500));

      // Modifiable en retard si la date prévue reste la même…
      ok(await planned.update(expense.id, scolarite(name: 'Scolarité T2')));
      // … mais pas vers une autre date passée.
      expect(
        errorsOf(
          await planned.update(
            expense.id,
            scolarite(due: DateTime(2026, 12, 1)),
          ),
        ),
        {PlannedFieldError.dueNotInFuture},
      );
    },
  );

  test('B · payée en avance : une opération à la date réelle, '
      'qui garde la date prévue, et plus de planifiée', () async {
    final expense = ok(await planned.create(scolarite()));
    now = DateTime(2026, 11, 25, 18);

    final paid = ok(await planned.pay(expense.id, DateTime(2026, 11, 25)));

    expect(paid.kind, TransactionKind.expense);
    expect(paid.amount, const Money(150000));
    expect(paid.description, 'Scolarité');
    expect(paid.occurredAt.toLocal(), now);
    expect(paid.planned?.dueDate, DateTime(2026, 12, 15));
    expect(paid.planned?.note, '2e trimestre');
    expect(await planned.watchAll().first, isEmpty);
    expect(await balance(), const Money(217500 - 150000));
  });

  test('payée un jour passé : datée de midi ce jour-là', () async {
    final expense = ok(await planned.create(scolarite()));
    now = DateTime(2026, 12, 17, 8);

    final paid = ok(await planned.pay(expense.id, DateTime(2026, 12, 15)));

    expect(paid.occurredAt.toLocal(), DateTime(2026, 12, 15, 12));
  });

  test('un paiement dans le futur est refusé', () async {
    final expense = ok(await planned.create(scolarite()));

    expect(
      await planned.pay(expense.id, DateTime(2026, 11, 21)),
      isA<Err<Transaction>>(),
    );
    expect(await planned.watchAll().first, hasLength(1));
  });

  test('supprimer l’opération payée supprime la dépense planifiée ; '
      'annuler remet tout', () async {
    final expense = ok(await planned.create(scolarite()));
    final paid = ok(await planned.pay(expense.id, DateTime(2026, 11, 20)));

    final deleted = ok(await transactions.delete(paid.id));
    expect(await planned.watchAll().first, isEmpty);
    expect(await balance(), const Money(217500));

    ok(await transactions.restore(deleted));
    final restored = await transactions.watchById(paid.id).first;
    expect(restored?.planned?.dueDate, DateTime(2026, 12, 15));
    expect(await balance(), const Money(217500 - 150000));
  });

  test('supprimer puis annuler une dépense planifiée', () async {
    final expense = ok(await planned.create(scolarite()));

    final deleted = ok(await planned.delete(expense.id));
    expect(await planned.watchAll().first, isEmpty);

    ok(await planned.restore(deleted));
    final back = await planned.watchById(expense.id).first;
    expect(back?.name, 'Scolarité');
    expect(back?.createdAt, expense.createdAt);
  });

  test('E · une dépense planifiée payée reste hors de la moyenne '
      'des dépenses courantes', () async {
    final expense = ok(await planned.create(scolarite()));
    ok(await planned.pay(expense.id, DateTime(2026, 11, 20)));

    final history = await ForecastRepository(
      db,
      () => now,
    ).watchHistory().first;

    expect(history.variableExpenseByDay, isEmpty);
    expect(history.netByDay[DateTime(2026, 11, 20)], -150000);
  });

  test('supprimer une catégorie déplace ses dépenses planifiées', () async {
    final categories = CategoriesRepository(db, () => now);
    final custom = ok(
      await categories.create(
        const CategoryDraft(kind: CategoryKind.expense, name: 'Cours du soir'),
      ),
    );
    final expense = ok(
      await planned.create(
        PlannedDraft(
          name: 'Inscription',
          amount: const Money(20000),
          dueDate: DateTime(2026, 12),
          categoryId: custom.id,
          accountId: ecobank.id,
        ),
      ),
    );

    ok(await categories.delete(custom.id));

    final moved = await planned.watchById(expense.id).first;
    expect(moved?.category.id, CategoryKind.expense.fallbackId);
  });
}
