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
import 'package:finance_app/features/transactions/data/transactions_repository.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/features/transactions/domain/transaction_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CategoriesRepository categories;
  late TransactionsRepository transactions;
  late Account wave;
  final now = DateTime.utc(2026, 11, 17, 9);

  T ok<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Échec inattendu : $failure'),
  };

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    categories = CategoriesRepository(db, () => now);
    transactions = TransactionsRepository(db, () => now);
    wave = ok(
      await AccountsRepository(db, () => now).create(
        const AccountDraft(
          type: AccountType.mobileMoney,
          name: 'Wave',
          openingBalance: Money(42000),
        ),
      ),
    );
  });
  tearDown(() => db.close());

  Future<Transaction> expense(String categoryId) async => ok(
    await transactions.create(
      TransactionDraft(
        kind: TransactionKind.expense,
        amount: const Money(1000),
        occurredAt: now,
        accountId: wave.id,
        categoryId: categoryId,
      ),
    ),
  );

  Future<String?> categoryOf(Transaction t) async =>
      (await transactions.watchById(t.id).first)?.category?.id;

  test('crée une catégorie et une sous-catégorie (icône du parent)', () async {
    final moto = ok(
      await categories.create(
        const CategoryDraft(
          kind: CategoryKind.expense,
          name: ' Moto ',
          iconKey: 'taxi',
        ),
      ),
    );
    final fuel = ok(
      await categories.create(
        CategoryDraft(
          kind: CategoryKind.expense,
          name: 'Essence',
          parentId: moto.id,
          iconKey: 'gift',
        ),
      ),
    );

    expect(moto.name, 'Moto');
    expect(moto.isCustom, isTrue);
    expect(fuel.parentId, moto.id);
    expect(fuel.iconKey, 'taxi');

    final groups = await categories.watchGroups(CategoryKind.expense).first;
    expect(
      groups.singleWhere((g) => g.category.id == moto.id).children.single.name,
      'Essence',
    );
  });

  test('noms uniques entre catégories sœurs, sans tenir compte de la casse',
      () async {
    expect(
      await categories.create(
        const CategoryDraft(kind: CategoryKind.expense, name: 'transport'),
      ),
      isA<Err<Category>>(),
    );
    // Même nom autorisé ailleurs : sous Transport, ou côté revenus.
    expect(
      await categories.create(
        const CategoryDraft(
          kind: CategoryKind.expense,
          name: 'Taxi moto',
          parentId: 'exp.transport',
        ),
      ),
      isA<Ok<Category>>(),
    );
    expect(
      await categories.create(
        const CategoryDraft(kind: CategoryKind.income, name: 'Transport'),
      ),
      isA<Ok<Category>>(),
    );
  });

  test('une catégorie prédéfinie se masque mais ne se supprime pas', () async {
    ok(await categories.setHidden('exp.leisure', hidden: true));
    final leisure = (await categories.watchGroups(CategoryKind.expense).first)
        .singleWhere((g) => g.category.id == 'exp.leisure')
        .category;
    expect(leisure.isHidden, isTrue);

    expect(await categories.delete('exp.leisure'), isA<Err<void>>());
    expect(await categories.rename('exp.leisure', 'Fun'), isA<Err<Category>>());
    // « Autre » ne peut pas être masquée.
    expect(
      await categories.setHidden('exp.other', hidden: true),
      isA<Err<void>>(),
    );
  });

  test('supprimer une catégorie personnalisée envoie ses opérations vers '
      '« Autre », sous-catégories comprises', () async {
    final moto = ok(
      await categories.create(
        const CategoryDraft(kind: CategoryKind.expense, name: 'Moto'),
      ),
    );
    final fuel = ok(
      await categories.create(
        CategoryDraft(
          kind: CategoryKind.expense,
          name: 'Essence',
          parentId: moto.id,
        ),
      ),
    );
    final a = await expense(moto.id);
    final b = await expense(fuel.id);
    expect(await categories.operationCount(moto.id), 2);

    ok(await categories.delete(moto.id));

    expect(await categoryOf(a), 'exp.other');
    expect(await categoryOf(b), 'exp.other');
    final groups = await categories.watchGroups(CategoryKind.expense).first;
    expect(groups.any((g) => g.category.id == moto.id), isFalse);
  });

  test('supprimer une sous-catégorie personnalisée renvoie ses opérations '
      'vers la catégorie parente', () async {
    final moto = ok(
      await categories.create(
        const CategoryDraft(
          kind: CategoryKind.expense,
          name: 'Moto',
          parentId: 'exp.transport',
        ),
      ),
    );
    final t = await expense(moto.id);

    ok(await categories.delete(moto.id));

    expect(await categoryOf(t), 'exp.transport');
  });

  test('renommer une catégorie personnalisée', () async {
    final moto = ok(
      await categories.create(
        const CategoryDraft(kind: CategoryKind.expense, name: 'Moto'),
      ),
    );

    expect(ok(await categories.rename(moto.id, 'Moto-taxi')).name, 'Moto-taxi');
    expect(
      await categories.rename(moto.id, 'Alimentation'),
      isA<Err<Category>>(),
    );
  });
}
