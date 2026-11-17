import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import 'theme/app_colors.dart';

/// Écran provisoire des sections pas encore développées.
/// À supprimer au fur et à mesure que les fonctionnalités arrivent.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({
    required this.title,
    this.showAppBar = false,
    super.key,
  });

  final String title;

  /// `true` pour un écran ouvert par-dessus les onglets (bouton retour).
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: showAppBar
          ? AppBar(backgroundColor: colors.background, title: Text(title))
          : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              if (!showAppBar)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                context.l10n.comingSoonMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: colors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
