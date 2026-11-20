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

  testWidgets('halo : seulement quand l’objectif devient atteint', (
    tester,
  ) async {
    var calls = 0;
    Widget halo(bool reached) => _app(
      ReachedHalo(
        reached: reached,
        color: Colors.amber,
        onReached: () => calls++,
        child: const SizedBox.square(dimension: 40),
      ),
    );

    // Déjà atteint à l'ouverture : rien.
    await tester.pumpWidget(halo(true));
    await tester.pumpAndSettle();
    expect(calls, 0);

    await tester.pumpWidget(halo(false));
    await tester.pumpWidget(halo(true));
    expect(calls, 1);
    await tester.pumpAndSettle();
    await tester.pumpWidget(halo(true));
    expect(calls, 1);
  });

  testWidgets('anneaux d’écoute : s’arrêtent avec l’écoute ; coche tracée', (
    tester,
  ) async {
    Widget rings(bool active) => _app(
      PulseRings(
        active: active,
        color: Colors.green,
        child: const SizedBox.square(dimension: 88),
      ),
    );
    await tester.pumpWidget(rings(true));
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(rings(false));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(_app(const DrawnCheck(color: Colors.green)));
    await tester.pumpAndSettle();
    expect(find.byType(DrawnCheck), findsOneWidget);
  });
}
