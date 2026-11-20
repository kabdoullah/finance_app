import 'package:finance_app/core/widgets/motion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child, {bool reduced = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(body: child),
  ),
);

Widget _counter(int value) => CountingValue(
  value: value,
  builder: (context, v) => Text('$v', textDirection: TextDirection.ltr),
);

void main() {
  testWidgets('un montant compte de 92 % à 100 %, jamais depuis zéro', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_counter(100000)));
    expect(find.text('92000'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('100000'), findsOneWidget);

    // Nouvelle valeur : compte depuis l'ancienne.
    await tester.pumpWidget(_app(_counter(120000)));
    expect(find.text('100000'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('120000'), findsOneWidget);
  });

  testWidgets('« Réduire les animations » : valeur finale tout de suite', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_counter(100000), reduced: true));
    await tester.pump();
    expect(find.text('100000'), findsOneWidget);

    await tester.pumpWidget(
      _app(const FadeSlideIn(index: 3, child: Text('Budgets')), reduced: true),
    );
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('cascade : apparaît puis reste visible', (tester) async {
    await tester.pumpWidget(
      _app(const FadeSlideIn(index: 2, child: Text('Budgets'))),
    );
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);

    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
  });
}
