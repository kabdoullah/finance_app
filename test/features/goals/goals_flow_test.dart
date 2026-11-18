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
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_app.dart';

void main() {
  late AppDatabase db;
  late Account wave;
  late GoalsRepository goals;

  setUp(() async {
    db = newTestDatabase();
    final accounts = AccountsRepository(db, () => testNow);
    wave = switch (await accounts.create(
      const AccountDraft(
        type: AccountType.mobileMoney,
        name: 'Wave',
        openingBalance: Money(42000),
      ),
    )) {
      Ok(:final value) => value,
      Err(:final failure) => fail('$failure'),
    };
    goals = GoalsRepository(db, () => testNow, accounts);
  });
  tearDown(() => db.close());

  Future<void> openGoals(WidgetTester tester) async {
    await pumpTestApp(tester, db);
    await tester.tap(find.text('Budgets').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objectifs'));
    await tester.pumpAndSettle();
  }

  testWidgets('créer un objectif puis y ajouter de l’argent', (tester) async {
    await openGoals(tester);
    expect(find.textContaining('Aucun objectif pour l'), findsOneWidget);

    await tester.tap(find.text('Nouvel objectif'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Téléphone'));
    await tester.enterText(find.byType(TextField).at(1), '150000');
    await tester.pumpAndSettle();
    // 6 mois par défaut : 150 000 ÷ 6 = 25 000 par mois.
    expect(
      find.text(
        'Il faudra mettre de côté environ 25 000 FCFA par mois.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text("Créer l'objectif"));
    await tester.pumpAndSettle();
    expect(find.text('Objectif « Téléphone » créé'), findsOneWidget);
    expect(
      find.text('150 000 FCFA · échéance le 15 mai 2027'),
      findsOneWidget,
    );

    await tester.tap(find.text('Voir mes objectifs'));
    await tester.pumpAndSettle();
    expect(find.text('1 objectif en cours'), findsOneWidget);
    expect(find.textContaining('pour y arriver à temps'), findsOneWidget);

    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    expect(find.text('Wave · 42 000 FCFA'), findsOneWidget);
    await tester.tap(find.text('Ajouter 10 000 FCFA'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        '10 000 FCFA ajoutés à « Téléphone » · '
        '10 000 / 150 000',
      ),
      findsOneWidget,
    );
  });

  testWidgets('retrait depuis le détail et lien sur la page Comptes', (
    tester,
  ) async {
    final created = await goals.create(
      GoalDraft(
        name: 'Moto',
        target: const Money(300000),
        iconKey: 'motorcycle',
        targetDate: DateTime(2027, 5, 15),
      ),
    );
    final goalId = (created as Ok<SavingsGoal>).value.id;
    await goals.contribute(goalId, wave.id, const Money(20000));

    await openGoals(tester);
    await tester.tap(find.text('Moto'));
    await tester.pumpAndSettle();
    expect(find.text('Reste 280 000 FCFA'), findsOneWidget);
    expect(find.text('Effort nécessaire'), findsOneWidget);

    await tester.tap(find.text('Retirer'));
    await tester.pumpAndSettle();
    // La réserve de l'objectif sur Wave est le plafond du retrait.
    expect(find.text('Wave · 20 000 FCFA'), findsOneWidget);
    await tester.tap(find.text('5 000'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirer 5 000 FCFA'));
    await tester.pumpAndSettle();
    expect(
      find.text('5 000 FCFA retirés. Effort mis à jour.'),
      findsOneWidget,
    );
    expect(find.text('Reste 285 000 FCFA'), findsOneWidget);
    // Historique, en bas de la page.
    await tester.scrollUntilVisible(find.text('Contribution'), 200);
    expect(find.text('Retrait'), findsOneWidget);

    // Page Comptes : ligne « Objectifs d'épargne ».
    await tester.tap(find.text('Transactions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mes comptes'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text("Objectifs d'épargne"), 200);
    expect(
      find.text('1 objectif · 15 000 FCFA mis de côté'),
      findsOneWidget,
    );
  });
}
