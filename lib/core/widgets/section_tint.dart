import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';

/// Teinte de section du design system, en haut d'écran seulement : sauge
/// (Accueil, Budgets, Comptes), ambre (Objectifs), ardoise (Prévisions,
/// Simulation, Assistant).
///
/// Enveloppe tout le [Scaffold] : comme sur les maquettes, la teinte part du
/// haut de l'écran (barre d'état et barre de titre comprises, rendues
/// transparentes) et se fond dans le papier sur [_fade].
class SectionTint extends StatelessWidget {
  const SectionTint({required this.color, required this.child, super.key});

  final Color color;
  final Widget child;

  /// Hauteur du fondu sur les maquettes (`var(--bg) 340px`).
  static const _fade = 340.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final stop = height.isFinite && height > _fade ? _fade / height : 1.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, context.colors.background],
              stops: [0, stop],
            ),
          ),
          child: Theme(
            data: theme.copyWith(
              scaffoldBackgroundColor: Colors.transparent,
              appBarTheme: theme.appBarTheme.copyWith(
                backgroundColor: Colors.transparent,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
