import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../l10n/l10n.dart';

/// Paramètres — version minimale : seule l'entrée « Catégories » existe pour
/// l'instant. Le reste (sécurité, sauvegarde…) viendra avec la fonctionnalité
/// « Sécurité et paramètres ».
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        children: [
          InkWell(
            onTap: () => context.push(AppRoutes.categories),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                spacing: 12,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.chip,
                    ),
                    child: Icon(AppIcons.tag, size: 18, color: colors.ink),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          l10n.categoriesTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.settingsCategoriesHint,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colors.inkTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    AppIcons.caretRight,
                    size: 14,
                    color: colors.inkTertiary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
