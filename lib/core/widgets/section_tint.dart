import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';

/// Teinte de section du design system, en haut d'écran seulement : sauge
/// (Accueil, Budgets), ambre (Objectifs), ardoise (Prévisions, Assistant).
/// Elle se fond dans le papier au premier tiers de l'écran.
class SectionTint extends StatelessWidget {
  const SectionTint({required this.color, required this.child, super.key});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, context.colors.background],
        stops: const [0, 0.35],
      ),
    ),
    child: child,
  );
}
