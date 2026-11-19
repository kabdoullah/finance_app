import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/errors/result.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:finance_app/features/budgets/data/budgets_repository.dart';
import 'package:finance_app/features/budgets/domain/budget_draft.dart';
import 'package:finance_app/features/notifications/data/notification_service.dart';
import 'package:finance_app/features/notifications/domain/notification_plan.dart';
import 'package:finance_app/features/recurring/data/recurring_repository.dart';
import 'package:finance_app/features/recurring/domain/recurrence.dart';
import 'package:finance_app/features/recurring/domain/recurring_draft.dart';
import 'package:finance_app/features/transactions/data/transactions_repository.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:finance_app/features/transactions/domain/transaction_draft.dart';
import 'package:finance_app/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// Service de test : retient ce qui serait programmé ou affiché.
class _FakeNotifications extends NotificationService {
  List<PlannedNotice> scheduled = const [];
  final shown = <PlannedNotice>[];
  int permissionRequests = 0;

  @override
  Future<void> initialize(void Function(String route) onTap) async {}

  @override
  Future<String?> launchRoute() async => null;

  @override
  Future<void> requestPermission() async => permissionRequests++;

  @override
  Future<void> replaceScheduled(
    List<PlannedNotice> notices,
    AppLocalizations l10n,
  ) async => scheduled = notices;

  @override
  Future<void> show(PlannedNotice notice, AppLocalizations l10n) async =>
      shown.add(notice);
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDatabase();
    final wave = switch (await AccountsRepository(db, () => testNow).create(
      const AccountDraft(
        type: AccountType.mobileMoney,
        name: 'Wave',
        openingBalance: Money(300000),
      ),
    )) {
      Ok<Account>(:final value) => value,
      Err(:final failure) => fail('$failure'),
    };
    final transactions = TransactionsRepository(db, () => testNow);
    await RecurringRepository(db, () => testNow, transactions).create(
      RecurringDraft(
        kind: TransactionKind.expense,
        name: 'Loyer',
        amount: const Money(75000),
        frequency: RecurrenceFrequency.month,
        startDate: DateTime(2026, 12),
        categoryId: 'exp.housing',
        accountId: wave.id,
      ),
    );
    await BudgetsRepository(
      db,
      () => testNow,
    ).create(const BudgetDraft(limit: Money(50000), categoryId: 'exp.food'));
    // 42 000 sur 50 000 : seuil d'alerte (80 %) franchi.
    await transactions.create(
      TransactionDraft(
        kind: TransactionKind.expense,
        amount: const Money(42000),
        occurredAt: DateTime(2026, 11, 10, 12),
        accountId: wave.id,
        categoryId: 'exp.food',
      ),
    );
  });
  tearDown(() => db.close());

  testWidgets('rappel programmé, alerte de budget une fois, interrupteur', (
    tester,
  ) async {
    final service = _FakeNotifications();
    await pumpTestApp(
      tester,
      db,
      overrides: [notificationServiceProvider.overrideWithValue(service)],
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(service.scheduled.map((n) => n.title), [
      'Loyer · 75 000 FCFA aujourd\'hui',
    ]);
    expect(service.scheduled.single.at, DateTime(2026, 12, 1, 9));
    expect(service.shown.single.title, 'Alimentation : 84 % du budget utilisé');
    expect(service.permissionRequests, 1);

    // Paramètres › Notifications : rappels coupés.
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tapSetting(tester, 'Rappels d\'échéance');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(service.scheduled, isEmpty);
    // Alerte déjà envoyée ce mois-ci : pas de seconde notification.
    expect(service.shown, hasLength(1));
    expect(service.permissionRequests, 1);
  });
}
