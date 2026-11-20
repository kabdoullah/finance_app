import 'package:finance_app/app/finao_splash.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Compte ses propres créations : un nouvel état = écran remonté.
class _Counter extends StatefulWidget {
  const _Counter();

  static int created = 0;

  @override
  State<_Counter> createState() {
    created++;
    return _CounterState();
  }
}

class _CounterState extends State<_Counter> {
  @override
  Widget build(BuildContext context) => const Text('App');
}

void main() {
  setUp(() => _Counter.created = 0);

  testWidgets('le splash s’efface sans remonter l’écran suivant', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: FinaoSplash(next: _Counter())),
    );
    expect(find.byType(SvgPicture), findsNWidgets(4));

    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsNothing);
    expect(find.text('App'), findsOneWidget);
    expect(_Counter.created, 1);
  });

  testWidgets('« Réduire les animations » : position finale, puis fondu', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: FinaoSplash(next: _Counter())),
      ),
    );
    await tester.pump();

    // Mot déjà affiché d'emblée (sans attendre ses 620 ms).
    final word = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.bySemanticsLabel('Finao'),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(word.opacity, 1);

    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets('le splash tient en paysage', (tester) async {
    tester.view
      ..physicalSize = const Size(844, 390)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: FinaoSplash(next: _Counter())),
    );
    await tester.pump(const Duration(milliseconds: 950));

    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });
}
