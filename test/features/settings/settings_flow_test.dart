import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/accounts/data/accounts_repository.dart';
import 'package:finance_app/features/accounts/domain/account_draft.dart';
import 'package:finance_app/features/accounts/domain/account_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_app.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDatabase();
    await AccountsRepository(db, () => testNow).create(
      const AccountDraft(
        type: AccountType.mobileMoney,
        name: 'Wave',
        openingBalance: Money(42000),
      ),
    );
  });
  tearDown(() => db.close());

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  testWidgets('masquer les montants : « •••• » puis l\'œil les affiche', (
    tester,
  ) async {
    await pumpTestApp(tester, db);
    expect(find.text('42 000'), findsOneWidget);

    await openSettings(tester);
    expect(find.text('FCFA (XOF)'), findsOneWidget);
    expect(
      find.text('Données stockées uniquement sur ce téléphone'),
      findsOneWidget,
    );
    await tapSetting(tester, 'Masquer les montants à l\'ouverture');
    await tester.pumpAndSettle();
    await back(tester);

    expect(find.text('42 000'), findsNothing);
    expect(find.text('••••'), findsOneWidget);

    await tester.tap(find.byTooltip('Afficher les montants'));
    await tester.pumpAndSettle();
    expect(find.text('42 000'), findsOneWidget);
  });

  testWidgets('thème : Sombre puis Automatique', (tester) async {
    await pumpTestApp(tester, db);
    ThemeMode mode() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;
    expect(mode(), ThemeMode.system);

    await openSettings(tester);
    await tapSetting(tester, 'Thème');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sombre'));
    await tester.pumpAndSettle();
    expect(mode(), ThemeMode.dark);
    expect(find.text('Sombre'), findsOneWidget);

    await tapSetting(tester, 'Thème');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automatique').last);
    await tester.pumpAndSettle();
    expect(mode(), ThemeMode.system);
  });
}
