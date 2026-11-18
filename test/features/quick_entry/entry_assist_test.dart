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
import 'package:finance_app/features/quick_entry/domain/entry_assist.dart';
import 'package:finance_app/features/quick_entry/domain/quick_entry_parser.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 18, 9);
  late QuickEntryContext context;
  late Map<String, Account> accounts;
  late EntryAssistPrompt prompt;
  const parser = QuickEntryParser();

  setUpAll(() async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = AccountsRepository(db, () => now);
    accounts = {};
    for (final (name, type) in [
      ('Wave', AccountType.mobileMoney),
      ('Orange Money', AccountType.mobileMoney),
      ('Espèces', AccountType.cash),
    ]) {
      final result = await repo.create(
        AccountDraft(type: type, name: name, openingBalance: Money.zero),
      );
      accounts[name] = (result as Ok<Account>).value;
    }
    final categories = CategoriesRepository(db, () => now);
    context = QuickEntryContext(
      now: now,
      accounts: accounts.values.toList(),
      expenseGroups: await categories.watchGroups(CategoryKind.expense).first,
      incomeGroups: await categories.watchGroups(CategoryKind.income).first,
      defaultAccountId: accounts['Wave']!.id,
    );
    prompt = EntryAssistPrompt.build(context);
    await db.close();
  });

  test('codes stables tirés des vraies catégories et comptes', () {
    expect(prompt.accounts.keys, ['wave', 'orange_money', 'especes']);
    expect(prompt.categories.keys, containsAll(['alimentation', 'salaire']));
    expect(prompt.categories['alimentation']!.id, 'exp.food');
    final properties = prompt.schema['properties']! as Map;
    expect((properties['account']! as Map)['enum'], [
      'wave',
      'orange_money',
      'especes',
      'none',
    ]);
    // Sous-catégories données en indice.
    expect(prompt.instruction, contains('transport (Taxi, Wôrô-wôrô'));
  });

  test('ne remplit que les champs « À vérifier », qui le restent', () {
    // « déj » : ni catégorie ni compte reconnus par l'analyseur.
    final op = parser.parse('déj 2500', context).single;
    expect(op.uncertain, {ParsedField.category, ParsedField.account});

    final merged = prompt.merge(
      op,
      '{"kind":"expense","amount":9999,"category":"alimentation",'
      '"account":"orange_money"}',
    );
    expect(merged.categoryId, 'exp.food');
    expect(merged.accountId, accounts['Orange Money']!.id);
    // Montant sûr : la réponse de Gemma est ignorée.
    expect(merged.amount, const Money(2500));
    expect(merged.uncertain, op.uncertain);
    expect(merged.source, 'déj 2500');
  });

  test('revenu reconnu par Gemma : type et catégorie changent ensemble', () {
    final op = parser.parse('client 45000 wave', context).single;
    expect(op.kind, TransactionKind.expense);
    final merged = prompt.merge(
      op,
      '{"kind":"income","amount":45000,"category":"vente","account":"wave"}',
    );
    expect(merged.kind, TransactionKind.income);
    expect(merged.categoryId, 'inc.sale');
  });

  test('réponse incohérente ou illisible : opération inchangée', () {
    final op = parser.parse('déj 2500', context).single;
    for (final raw in [
      'pas du json',
      // Catégorie de dépense annoncée comme revenu.
      '{"kind":"income","amount":0,"category":"alimentation","account":"none"}',
      '{"kind":"expense","amount":0,"category":"none","account":"none"}',
    ]) {
      final merged = prompt.merge(op, raw);
      expect(merged.categoryId, op.categoryId, reason: raw);
      expect(merged.kind, op.kind, reason: raw);
      expect(merged.accountId, op.accountId, reason: raw);
    }
  });
}
