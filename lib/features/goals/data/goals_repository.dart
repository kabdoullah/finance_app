import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/result.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/month.dart';
import '../../accounts/data/accounts_repository.dart';
import '../domain/goal_draft.dart';
import '../domain/savings_goal.dart';

/// Objectifs d'épargne et réserves associées. Aucune opération n'est créée :
/// l'argent reste sur les comptes, il est seulement réservé.
class GoalsRepository {
  GoalsRepository(
    this._db,
    this._clock,
    this._accounts, {
    String Function()? newId,
  }) : _newId = newId ?? const Uuid().v4;

  final AppDatabase _db;
  final Clock _clock;
  final AccountsRepository _accounts;
  final String Function() _newId;

  $SavingsGoalsTable get _goals => _db.savingsGoals;
  $GoalMovementsTable get _movements => _db.goalMovements;

  /// Somme signée des mouvements (contribution +, retrait −).
  static const _signedSum =
      "COALESCE(SUM(CASE m.kind WHEN 'contribution' THEN m.amount "
      'ELSE -m.amount END), 0)';

  /// Objectifs avec leur épargne, du plus ancien au plus récent.
  Stream<List<SavingsGoal>> watchAll() => _db
      .customSelect(
        'SELECT g.*, $_signedSum AS saved FROM savings_goals g '
        'LEFT JOIN goal_movements m ON m.goal_id = g.id '
        'GROUP BY g.id ORDER BY g.created_at ASC',
        readsFrom: {_goals, _movements},
      )
      .map((row) => _toGoal(_goals.map(row.data), row.read<int>('saved')))
      .watch();

  /// Contributions et retraits d'un objectif, du plus récent au plus ancien.
  Stream<List<GoalMovement>> watchMovements(String goalId) {
    final query =
        _db.select(_movements).join([
            innerJoin(
              _db.accounts,
              _db.accounts.id.equalsExp(_movements.accountId),
            ),
          ])
          ..where(_movements.goalId.equals(goalId))
          ..orderBy([
            OrderingTerm.desc(_movements.occurredAt),
            OrderingTerm.desc(_movements.createdAt),
          ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          _toMovement(
            row.readTable(_movements),
            row.readTable(_db.accounts).name,
          ),
      ],
    );
  }

  /// Montant réservé par compte, tous objectifs confondus (ou pour
  /// [goalId] seulement). Les comptes sans réserve sont absents.
  Stream<Map<String, Money>> watchReservedByAccount({String? goalId}) =>
      _reservedByAccount(goalId: goalId).watch().map(_toMap);

  Future<Result<SavingsGoal>> create(GoalDraft draft) => _guard(() async {
    final errors = _validate(draft);
    if (errors.isNotEmpty) return Err(ValidationFailure(errors));
    final id = _newId();
    final now = _nowMs();
    await _goals.insertOne(
      _companion(
        draft,
      ).copyWith(id: Value(id), createdAt: Value(now), updatedAt: Value(now)),
    );
    return Ok((await _get(id))!);
  });

  Future<Result<SavingsGoal>> update(String id, GoalDraft draft) =>
      _guard(() async {
        final errors = _validate(draft);
        if (errors.isNotEmpty) return Err(ValidationFailure(errors));
        final count = await (_db.update(_goals)..where((g) => g.id.equals(id)))
            .write(_companion(draft).copyWith(updatedAt: Value(_nowMs())));
        if (count == 0) return const Err(NotFoundFailure());
        return Ok((await _get(id))!);
      });

  /// Supprime l'objectif et ses mouvements : les réserves sont libérées,
  /// aucun solde ne change.
  Future<Result<void>> delete(String id) => _guard(() async {
    final count = await (_db.delete(
      _goals,
    )..where((g) => g.id.equals(id))).go();
    return count == 0 ? const Err(NotFoundFailure()) : const Ok(null);
  });

  /// Réserve [amount] du compte pour l'objectif, dans la limite du
  /// disponible du compte (solde − déjà réservé, tous objectifs).
  Future<Result<SavingsGoal>> contribute(
    String goalId,
    String accountId,
    Money amount,
  ) => _move(GoalMovementKind.contribution, goalId, accountId, amount);

  /// Libère [amount] de la réserve de l'objectif sur ce compte.
  Future<Result<SavingsGoal>> withdraw(
    String goalId,
    String accountId,
    Money amount,
  ) => _move(GoalMovementKind.withdrawal, goalId, accountId, amount);

  /// Disponible d'un compte : solde − réservé pour tous les objectifs.
  Future<Money?> availableOn(String accountId) async {
    final account = await _accounts.getById(accountId);
    if (account == null || account.isArchived) return null;
    final reserved = _toMap(await _reservedByAccount().get());
    return account.balance - (reserved[accountId] ?? Money.zero);
  }

  /// « En moyenne, il te reste X FCFA par mois après tes dépenses » :
  /// revenus − dépenses, moyenne des 3 derniers mois complets (transferts
  /// exclus). `null` sans opération sur la période.
  Future<Money?> averageMonthlySurplus() async {
    final current = Month.of(_clock());
    final from = current.previous.previous.previous.start;
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS n, COALESCE(SUM(CASE kind '
          "WHEN 'income' THEN amount WHEN 'expense' THEN -amount "
          'ELSE 0 END), 0) AS net FROM transactions '
          "WHERE kind <> 'transfer' AND occurred_at >= ? AND occurred_at < ?",
          variables: [
            Variable.withInt(_ms(from)),
            Variable.withInt(_ms(current.start)),
          ],
          readsFrom: {_db.transactions},
        )
        .getSingle();
    if (row.read<int>('n') == 0) return null;
    return Money(row.read<int>('net') ~/ 3);
  }

  /// Historique minimal avant d'afficher un rythme ou un montant conseillé.
  static const minHistoryDays = 30;

  /// Rythme d'épargne moyen de l'objectif sur les 3 derniers mois
  /// (contributions − retraits), divisé par les mois réellement écoulés
  /// depuis sa création (au plus 3). `null` si l'objectif a moins de
  /// [minHistoryDays] jours.
  Future<Money?> averageMonthlyContribution(String goalId) async {
    final goal = await _get(goalId);
    if (goal == null) return null;
    final now = _clock();
    final age = now.difference(goal.createdAt).inHours / 24;
    if (age < minHistoryDays) return null;
    final from = DateTime(now.year, now.month - 3, now.day);
    final row = await _db
        .customSelect(
          'SELECT $_signedSum AS net FROM goal_movements m '
          'WHERE m.goal_id = ? AND m.occurred_at >= ?',
          variables: [Variable.withString(goalId), Variable.withInt(_ms(from))],
          readsFrom: {_movements},
        )
        .getSingle();
    final months = (age / (365.25 / 12)).clamp(1.0, 3.0);
    return Money((row.read<int>('net') / months).round());
  }

  /// Dépenses moyennes par mois sur les 3 derniers mois complets
  /// (transferts exclus), divisées par les mois couverts par l'historique.
  /// `null` avec moins de [minHistoryDays] jours d'historique.
  Future<Money?> averageMonthlyExpenses() async {
    final now = _clock();
    final current = Month.of(now);
    final firstRow = await _db
        .customSelect(
          'SELECT MIN(occurred_at) AS first FROM transactions',
          readsFrom: {_db.transactions},
        )
        .getSingle();
    final firstMs = firstRow.readNullable<int>('first');
    if (firstMs == null) return null;
    final first = DateTime.fromMillisecondsSinceEpoch(firstMs, isUtc: true);
    if (now.difference(first).inHours / 24 < minHistoryDays) return null;
    final months = [
      current.previous,
      current.previous.previous,
      current.previous.previous.previous,
    ].where((m) => first.toLocal().isBefore(m.end)).toList();
    if (months.isEmpty) return null;
    final row = await _db
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions '
          "WHERE kind = 'expense' AND occurred_at >= ? AND occurred_at < ?",
          variables: [
            Variable.withInt(_ms(months.last.start)),
            Variable.withInt(_ms(current.start)),
          ],
          readsFrom: {_db.transactions},
        )
        .getSingle();
    return Money(row.read<int>('total') ~/ months.length);
  }

  Future<Result<SavingsGoal>> _move(
    GoalMovementKind kind,
    String goalId,
    String accountId,
    Money amount,
  ) => _guard(
    () => _db.transaction(() async {
      if (await _get(goalId) == null) return const Err(NotFoundFailure());
      if (amount.value <= 0) {
        return const Err(ValidationFailure({GoalMovementError.amountMissing}));
      }
      final Money limit;
      if (kind == GoalMovementKind.contribution) {
        final available = await availableOn(accountId);
        if (available == null) {
          return const Err(
            ValidationFailure({GoalMovementError.accountUnavailable}),
          );
        }
        limit = available;
      } else {
        final reserved = _toMap(await _reservedByAccount(goalId: goalId).get());
        limit = reserved[accountId] ?? Money.zero;
      }
      if (amount.value > limit.value) {
        return const Err(ValidationFailure({GoalMovementError.amountTooLarge}));
      }
      final now = _nowMs();
      await _movements.insertOne(
        GoalMovementsCompanion.insert(
          id: _newId(),
          goalId: goalId,
          kind: kind.storageValue,
          amount: amount.value,
          accountId: accountId,
          occurredAt: now,
          createdAt: now,
        ),
      );
      return Ok((await _get(goalId))!);
    }),
  );

  Selectable<(String, Money)> _reservedByAccount({String? goalId}) => _db
      .customSelect(
        'SELECT m.account_id AS account_id, $_signedSum AS reserved '
        'FROM goal_movements m '
        '${goalId == null ? '' : 'WHERE m.goal_id = ? '}'
        'GROUP BY m.account_id',
        variables: [if (goalId != null) Variable.withString(goalId)],
        readsFrom: {_movements},
      )
      .map(
        (row) =>
            (row.read<String>('account_id'), Money(row.read<int>('reserved'))),
      );

  static Map<String, Money> _toMap(List<(String, Money)> rows) => {
    for (final (accountId, reserved) in rows)
      if (reserved.value > 0) accountId: reserved,
  };

  Set<GoalFieldError> _validate(GoalDraft draft) {
    final errors = draft.validate();
    final date = draft.targetDate;
    if (date != null &&
        !CalendarDate.of(date).isAfter(CalendarDate.of(_clock()))) {
      errors.add(GoalFieldError.dateInPast);
    }
    return errors;
  }

  Future<SavingsGoal?> _get(String id) async {
    final row = await _db
        .customSelect(
          'SELECT g.*, $_signedSum AS saved FROM savings_goals g '
          'LEFT JOIN goal_movements m ON m.goal_id = g.id '
          'WHERE g.id = ? GROUP BY g.id',
          variables: [Variable.withString(id)],
          readsFrom: {_goals, _movements},
        )
        .getSingleOrNull();
    return row == null
        ? null
        : _toGoal(_goals.map(row.data), row.read<int>('saved'));
  }

  SavingsGoalsCompanion _companion(GoalDraft draft) => SavingsGoalsCompanion(
    name: Value(draft.normalizedName),
    iconKey: Value(draft.iconKey),
    targetAmount: Value(draft.target.value),
    targetDate: Value(
      draft.targetDate == null ? null : CalendarDate.format(draft.targetDate!),
    ),
  );

  static SavingsGoal _toGoal(GoalRow row, int saved) {
    final date = row.targetDate;
    return SavingsGoal(
      id: row.id,
      name: row.name,
      iconKey: row.iconKey,
      target: Money(row.targetAmount),
      saved: Money(saved),
      targetDate: date == null ? null : CalendarDate.parse(date),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
    );
  }

  static GoalMovement _toMovement(GoalMovementRow row, String accountName) =>
      GoalMovement(
        id: row.id,
        kind: GoalMovementKind.fromStorage(row.kind),
        amount: Money(row.amount),
        accountId: row.accountId,
        accountName: accountName,
        occurredAt: DateTime.fromMillisecondsSinceEpoch(
          row.occurredAt,
          isUtc: true,
        ),
      );

  int _nowMs() => _ms(_clock());

  static int _ms(DateTime date) => date.toUtc().millisecondsSinceEpoch;

  /// Convertit les erreurs SQLite inattendues en [StorageFailure].
  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      return Err(StorageFailure(error, stackTrace));
    }
  }
}
