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
import 'package:finance_app/features/recurring/data/recurring_repository.dart';
import 'package:finance_app/features/recurring/domain/recurrence.dart';
import 'package:finance_app/features/recurring/domain/recurring_draft.dart';
import 'package:finance_app/features/recurring/domain/recurring_operation.dart';
import 'package:finance_app/features/transactions/data/transactions_repository.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Recurrence', () {
    test('un 31 tombe le dernier jour des mois courts, puis redevient 31', () {
      final r = Recurrence(
        frequency: RecurrenceFrequency.month,
        start: DateTime(2026, 1, 31),
      );
      expect(
        [for (var k = 0; k < 4; k++) r.occurrence(k)],
        [
          DateTime(2026, 1, 31),
          DateTime(2026, 2, 28),
          DateTime(2026, 3, 31),
          DateTime(2026, 4, 30),
        ],
      );
      expect(r.after(DateTime(2026, 2, 28)), DateTime(2026, 3, 31));
    });

    test('29 février → 28 février les années non bissextiles', () {
      final r = Recurrence(
        frequency: RecurrenceFrequency.year,
        start: DateTime(2028, 2, 29),
      );
      expect(r.occurrence(1), DateTime(2029, 2, 28));
      expect(r.occurrence(4), DateTime(2032, 2, 29));
    });

    test('hebdomadaire, première échéance après une date, fin et nombre', () {
      final r = Recurrence(
        frequency: RecurrenceFrequency.week,
        start: DateTime(2026, 11, 7), // samedi
        end: DateTime(2026, 12, 5),
      );
      expect(r.firstOnOrAfter(DateTime(2026, 11, 18)), DateTime(2026, 11, 21));
      expect(r.after(DateTime(2026, 12, 5)), isNull);
      expect(r.count, 5);
    });
  });

  test('totaux mensuels : hebdo ×52÷12, annuel ÷12, pause exclue', () {
    RecurringOperation op(
      int amount,
      RecurrenceFrequency frequency, {
      TransactionKind kind = TransactionKind.expense,
      bool paused = false,
    }) => RecurringOperation(
      id: '$amount',
      kind: kind,
      name: 'x',
      amount: Money(amount),
      isVariable: false,
      category: const Category(
        id: 'c',
        name: 'c',
        kind: CategoryKind.expense,
        iconKey: 'tag',
      ),
      accountId: 'a',
      accountName: 'Wave',
      recurrence: Recurrence(frequency: frequency, start: DateTime(2026)),
      nextDue: DateTime(2026, 12),
      askBeforeRecording: true,
      isPaused: paused,
    );
    final totals = RecurringTotals.of([
      op(380000, RecurrenceFrequency.month, kind: TransactionKind.income),
      op(3000, RecurrenceFrequency.week), // 13 000 / mois
      op(120000, RecurrenceFrequency.year), // 10 000 / mois
      op(99999, RecurrenceFrequency.month, paused: true),
    ]);
    expect(totals.income, const Money(380000));
    expect(totals.expense, const Money(23000));
  });

  group('RecurringRepository', () {
    late AppDatabase db;
    final now = DateTime(2026, 11, 18, 9);
    late RecurringRepository recurring;
    late TransactionsRepository transactions;
    late Account wave;

    T ok<T>(Result<T> result) => switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => fail('Échec inattendu : $failure'),
    };

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      transactions = TransactionsRepository(db, () => now);
      recurring = RecurringRepository(db, () => now, transactions);
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

    RecurringDraft draft({
      DateTime? start,
      bool ask = true,
      String category = 'exp.leisure',
    }) => RecurringDraft(
      kind: TransactionKind.expense,
      name: '  Canal+  ',
      amount: const Money(12500),
      frequency: RecurrenceFrequency.month,
      startDate: start ?? DateTime(2026, 9, 20),
      categoryId: category,
      accountId: wave.id,
      askBeforeRecording: ask,
    );

    Future<List<Transaction>> recorded() =>
        transactions.watchForAccount(wave.id).first;

    test('« Me demander » : en attente, enregistrer puis ignorer', () async {
      final canal = ok(await recurring.create(draft()));
      expect(canal.name, 'Canal+');

      // Le 18 nov. : 20 sept. et 20 oct. sont passés, pas encore le 20 nov.
      final pending = PendingOccurrence.of([canal], now);
      expect(pending.map((p) => p.due), [
        DateTime(2026, 9, 20),
        DateTime(2026, 10, 20),
      ]);
      expect(pending.map((p) => p.isFirst), [true, false]);

      // Seule la plus ancienne se traite.
      expect(
        await recurring.record(canal.id, DateTime(2026, 10, 20)),
        isA<Err<Transaction>>(),
      );
      final t = ok(await recurring.record(canal.id, DateTime(2026, 9, 20)));
      expect(t.entryMethod, EntryMethod.recurring);
      expect(t.recurringId, canal.id);
      expect(t.description, 'Canal+');
      expect(t.occurredAt.toLocal(), DateTime(2026, 9, 20, 8));

      ok(await recurring.skip(canal.id, DateTime(2026, 10, 20)));
      expect((await recurring.get(canal.id))!.nextDue, DateTime(2026, 11, 20));
      expect(await recorded(), hasLength(1));
    });

    test('montant variable : le montant réel remplace l’estimation', () async {
      final op = ok(
        await recurring.create(draft(start: DateTime(2026, 11, 13))),
      );
      final t = ok(
        await recurring.record(
          op.id,
          DateTime(2026, 11, 13),
          amount: const Money(15800),
        ),
      );
      expect(t.amount, const Money(15800));
    });

    test('automatique : rattrape chaque échéance manquée à sa date', () async {
      final op = ok(
        await recurring.create(draft(start: DateTime(2026, 9, 20), ask: false)),
      );
      expect(await recurring.recordAutomatic(), 2); // 20 sept. et 20 oct.
      expect(
        (await recorded()).map((t) => t.occurredAt.toLocal().month),
        unorderedEquals([9, 10]),
      );
      expect((await recurring.get(op.id))!.nextDue, DateTime(2026, 11, 20));
      expect(await recurring.recordAutomatic(), 0);
    });

    test(
      'reprise après pause : les échéances de la pause sont ignorées',
      () async {
        final op = ok(
          await recurring.create(draft(start: DateTime(2026, 8, 20))),
        );
        ok(await recurring.setPaused(op.id, paused: true));
        expect(
          PendingOccurrence.of([(await recurring.get(op.id))!], now),
          isEmpty,
        );
        final resumed = ok(await recurring.setPaused(op.id, paused: false));
        expect(resumed.nextDue, DateTime(2026, 11, 20));
      },
    );

    test('supprimer le modèle détache ses opérations', () async {
      final op = ok(await recurring.create(draft()));
      ok(await recurring.record(op.id, DateTime(2026, 9, 20)));
      ok(await recurring.delete(op.id));
      final kept = await recorded();
      expect(kept, hasLength(1));
      expect(kept.single.recurringId, isNull);
    });

    test('supprimer sa catégorie réaffecte le modèle', () async {
      final categories = CategoriesRepository(db, () => now);
      final custom = ok(
        await categories.create(
          const CategoryDraft(
            kind: CategoryKind.expense,
            name: 'Abonnements TV',
          ),
        ),
      );
      final op = ok(await recurring.create(draft(category: custom.id)));
      ok(await categories.delete(custom.id));
      expect((await recurring.get(op.id))!.category.id, 'exp.other');
    });
  });
}
