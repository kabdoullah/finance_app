import 'package:drift/native.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:flutter_test/flutter_test.dart';

const _wave = AccountDraft(
  type: AccountType.mobileMoney,
  name: 'Wave',
  openingBalance: Money(15000),
);

void main() {
  late AppDatabase db;
  late AccountsRepository repository;
  var now = DateTime.utc(2026, 11, 15, 9);
  var nextId = 0;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    nextId = 0;
    now = DateTime.utc(2026, 11, 15, 9);
    repository = AccountsRepository(
      db,
      () => now,
      newId: () => 'id-${nextId++}',
    );
  });
  tearDown(() => db.close());

  Account created(Result<Account> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Création refusée : $failure'),
  };

  Set<AccountFieldError> errorsOf(Result<Object?> result) => switch (result) {
    Err(failure: ValidationFailure<AccountFieldError>(:final errors)) => errors,
    _ => fail('Échec de validation attendu, obtenu : $result'),
  };

  test('crée un compte : solde = solde initial, nom normalisé', () async {
    final account = created(
      await repository.create(
        const AccountDraft(
          type: AccountType.mobileMoney,
          name: '  Wave ',
          openingBalance: Money(15000),
        ),
      ),
    );

    expect(account.id, 'id-0');
    expect(account.name, 'Wave');
    expect(account.balance, const Money(15000));
    expect(account.createdAt, now);
    expect(await repository.watchActive().first, hasLength(1));
  });

  test('refuse un brouillon invalide sans rien écrire', () async {
    final result = await repository.create(const AccountDraft());

    expect(errorsOf(result), {
      AccountFieldError.typeMissing,
      AccountFieldError.nameMissing,
    });
    expect(await repository.watchActive().first, isEmpty);
  });

  test('deux comptes actifs ne peuvent pas porter le même nom', () async {
    created(await repository.create(_wave));

    final duplicate = await repository.create(
      const AccountDraft(type: AccountType.bank, name: 'WAVE'),
    );

    expect(errorsOf(duplicate), {AccountFieldError.nameTaken});
  });

  test('l’index unique protège aussi la base en direct', () async {
    created(await repository.create(_wave));

    expect(
      () => db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: 'x',
              name: 'wave',
              type: 'bank',
              openingBalance: 0,
              createdAt: 0,
              updatedAt: 0,
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('modifie un compte en gardant son propre nom', () async {
    final wave = created(await repository.create(_wave));

    final updated = created(
      await repository.update(
        wave.id,
        const AccountDraft(
          type: AccountType.mobileMoney,
          name: 'Wave',
          openingBalance: Money(20000),
        ),
      ),
    );

    expect(updated.balance, const Money(20000));
  });

  test('archiver retire le compte des actifs ; restaurer le remet', () async {
    final wave = created(await repository.create(_wave));
    now = DateTime.utc(2026, 11, 16);

    expect(await repository.archive(wave.id), isA<Ok<void>>());
    expect(await repository.watchActive().first, isEmpty);
    final archived = (await repository.watchArchived().first).single;
    expect(archived.archivedAt, now);

    // Un nom libéré par l'archivage peut être réutilisé…
    final newWave = created(await repository.create(_wave));
    // … mais restaurer l'ancien créerait un doublon.
    expect(errorsOf(await repository.restore(wave.id)), {
      AccountFieldError.nameTaken,
    });

    await repository.delete(newWave.id);
    expect(await repository.restore(wave.id), isA<Ok<void>>());
    expect((await repository.watchById(wave.id).first)?.isArchived, isFalse);
  });

  test('supprimer efface le compte définitivement', () async {
    final wave = created(await repository.create(_wave));

    expect(await repository.delete(wave.id), isA<Ok<void>>());
    expect(await repository.watchById(wave.id).first, isNull);
    expect(
      await repository.delete(wave.id),
      isA<Err<void>>().having(
        (e) => e.failure,
        'failure',
        isA<NotFoundFailure>(),
      ),
    );
  });
}
