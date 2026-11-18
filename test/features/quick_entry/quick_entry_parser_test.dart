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
import 'package:finance_app/features/quick_entry/domain/quick_entry_parser.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 18, 9);
  late QuickEntryContext context;
  late Map<String, Account> accounts;
  late Map<String, String> mainCategory;
  const parser = QuickEntryParser();

  setUpAll(() async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = AccountsRepository(db, () => now);
    accounts = {};
    for (final (name, type) in [
      ('Wave', AccountType.mobileMoney),
      ('Orange Money', AccountType.mobileMoney),
      ('Espèces', AccountType.cash),
      ('Ecobank', AccountType.bank),
      ('MTN MoMo', AccountType.mobileMoney),
    ]) {
      final result = await repo.create(
        AccountDraft(type: type, name: name, openingBalance: Money.zero),
      );
      accounts[name] = (result as Ok<Account>).value;
    }
    final categories = CategoriesRepository(db, () => now);
    final expense = await categories.watchGroups(CategoryKind.expense).first;
    final income = await categories.watchGroups(CategoryKind.income).first;
    mainCategory = {
      for (final g in [...expense, ...income]) ...{
        g.category.id: g.category.id,
        for (final c in g.children) c.id: g.category.id,
      },
    };
    context = QuickEntryContext(
      now: now,
      accounts: accounts.values.toList(),
      expenseGroups: expense,
      incomeGroups: income,
      defaultAccountId: accounts['Wave']!.id,
    );
    await db.close();
  });

  ParsedOperation single(String text) {
    final ops = parser.parse(text, context);
    expect(ops, hasLength(1), reason: text);
    return ops.single;
  }

  void expectOp(
    String text, {
    required TransactionKind kind,
    required int amount,
    String? category,
    String? account,
    String? to,
    int daysAgo = 0,
  }) {
    final op = single(text);
    expect(op.kind, kind, reason: text);
    expect(op.amount, Money(amount), reason: text);
    if (category != null) {
      expect(mainCategory[op.categoryId], category, reason: text);
    }
    if (account != null) {
      expect(op.accountId, accounts[account]!.id, reason: text);
    }
    if (to != null) expect(op.toAccountId, accounts[to]!.id, reason: text);
    expect(op.date, DateTime(2026, 11, 18 - daysAgo), reason: text);
  }

  group('saisies du POC', () {
    test('dépenses courantes', () {
      expectOp(
        'taxi 2000 wave',
        kind: TransactionKind.expense,
        amount: 2000,
        category: 'exp.transport',
        account: 'Wave',
      );
      expectOp(
        'wôrô 500 espèces hier',
        kind: TransactionKind.expense,
        amount: 500,
        category: 'exp.transport',
        account: 'Espèces',
        daysAgo: 1,
      );
      expectOp(
        'marché 7500 orange money',
        kind: TransactionKind.expense,
        amount: 7500,
        category: 'exp.food',
        account: 'Orange Money',
      );
      expectOp(
        'loyer 75 000 ecobank',
        kind: TransactionKind.expense,
        amount: 75000,
        category: 'exp.housing',
        account: 'Ecobank',
      );
      expectOp(
        'courant CIE 14000 wave',
        kind: TransactionKind.expense,
        amount: 14000,
        category: 'exp.bills',
        account: 'Wave',
      );
      expectOp(
        'crédit téléphone 1000 orange',
        kind: TransactionKind.expense,
        amount: 1000,
        category: 'exp.bills',
        account: 'Orange Money',
      );
      expectOp(
        'tontine 40 mille espèces',
        kind: TransactionKind.expense,
        amount: 40000,
        category: 'exp.tontine',
        account: 'Espèces',
      );
      expectOp(
        'frais de scolarité 50000 ecobank',
        kind: TransactionKind.expense,
        amount: 50000,
        category: 'exp.education',
        account: 'Ecobank',
      );
      expectOp(
        'pagne 12000 wave',
        kind: TransactionKind.expense,
        amount: 12000,
        category: 'exp.clothing',
        account: 'Wave',
      );
      expectOp(
        'envoi au village 25000 mtn',
        kind: TransactionKind.expense,
        amount: 25000,
        category: 'exp.family',
        account: 'MTN MoMo',
      );
      expectOp(
        'cinéma 4000 hier wave',
        kind: TransactionKind.expense,
        amount: 4000,
        category: 'exp.leisure',
        account: 'Wave',
        daysAgo: 1,
      );
    });

    test('revenus et transfert', () {
      expectOp(
        'salaire 380000 sur ecobank',
        kind: TransactionKind.income,
        amount: 380000,
        category: 'inc.salary',
        account: 'Ecobank',
      );
      expectOp(
        "maman m'a envoyé 20000 sur wave",
        kind: TransactionKind.income,
        amount: 20000,
        category: 'inc.received',
        account: 'Wave',
      );
      expectOp(
        "vente d'attiéké 15000 espèces",
        kind: TransactionKind.income,
        amount: 15000,
        category: 'inc.sale',
        account: 'Espèces',
      );
      expectOp(
        'transfert 50000 de ecobank vers wave',
        kind: TransactionKind.transfer,
        amount: 50000,
        account: 'Ecobank',
        to: 'Wave',
      );
    });

    test('sans compte : dernier compte utilisé, à vérifier', () {
      final op = single('gbaka 300');
      expect(op.accountId, accounts['Wave']!.id);
      expect(op.uncertain, {ParsedField.account});
      expect(mainCategory[op.categoryId], 'exp.transport');
    });
  });

  group('reconnaissance vocale (transcriptions du POC)', () {
    test('déformations corrigées par le dictionnaire', () {
      expectOp(
        'taxi 2000 sur waze',
        kind: TransactionKind.expense,
        amount: 2000,
        category: 'exp.transport',
        account: 'Wave',
      );
      expectOp(
        'GABA 1000 francs',
        kind: TransactionKind.expense,
        amount: 1000,
        category: 'exp.food',
      );
      expectOp(
        'tantine 40000',
        kind: TransactionKind.expense,
        amount: 40000,
        category: 'exp.tontine',
      );
    });

    test('catégorie absente : « Autre », à vérifier', () {
      final op = single('500 espèces');
      expect(op.amount, const Money(500));
      expect(op.accountId, accounts['Espèces']!.id);
      expect(op.categoryId, 'exp.other');
      expect(op.uncertain, {ParsedField.category});
    });
  });

  test('montants en lettres', () {
    expect(
      single('salaire trois cent quatre-vingt mille sur Ecobank').amount,
      const Money(380000),
    );
    expect(single('garba mille hier').amount, const Money(1000));
    expect(single('taxi deux mille cinq cents').amount, const Money(2500));
  });

  test('plusieurs opérations et date héritée (maquette)', () {
    final ops = parser.parse(
      'Hier, 2 000 de crédit Orange et 1 500 de pain en espèces',
      context,
    );
    expect(ops, hasLength(2));
    expect(ops[0].amount, const Money(2000));
    expect(mainCategory[ops[0].categoryId], 'exp.bills');
    expect(ops[0].accountId, accounts['Orange Money']!.id);
    expect(ops[1].amount, const Money(1500));
    expect(mainCategory[ops[1].categoryId], 'exp.food');
    expect(ops[1].accountId, accounts['Espèces']!.id);
    expect(ops.map((o) => o.date), everyElement(DateTime(2026, 11, 17)));
  });

  test('un seul compte cité : il vaut pour toute la phrase', () {
    final ops = parser.parse('Déjeuner 2 500 et taxi 1 000 avec Wave', context);
    expect(ops, hasLength(2));
    expect(ops.map((o) => o.accountId), everyElement(accounts['Wave']!.id));
    expect(ops.map((o) => o.uncertain), everyElement(isEmpty));
  });

  test('description sans montant ni date', () {
    final ops = parser.parse(
      'Hier, 2 000 de crédit Orange et 1 500 de pain en espèces',
      context,
    );
    expect(ops.map((o) => o.description), ['Crédit Orange', 'Pain en espèces']);
    expect(single('tontine 40 mille espèces').description, 'Tontine espèces');
    expect(
      single('frais de scolarité 50000 ecobank').description,
      'Frais de scolarité ecobank',
    );
  });

  test('sans montant : opération gardée, montant à vérifier', () {
    final op = single('taxi wave');
    expect(op.amount, isNull);
    expect(op.uncertain, contains(ParsedField.amount));
  });
}
