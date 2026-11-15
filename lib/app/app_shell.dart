import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import 'theme/app_colors.dart';
import 'theme/app_icons.dart';

/// Coque des onglets principaux : contenu + barre de navigation basse.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final destinations = [
      (l10n.navHome, AppIcons.house, AppIcons.houseFill),
      (l10n.navTransactions, AppIcons.arrowsDownUp, AppIcons.arrowsDownUpFill),
      (l10n.navBudgets, AppIcons.chartDonut, AppIcons.chartDonutFill),
      (l10n.navForecast, AppIcons.chartLine, AppIcons.chartLineFill),
      (l10n.navAssistant, AppIcons.chatCircleText, AppIcons.chatCircleTextFill),
    ];
    final current = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _NavigationBar(
        children: [
          for (final (index, (label, icon, selectedIcon))
              in destinations.indexed)
            _NavigationItem(
              label: label,
              icon: index == current ? selectedIcon : icon,
              selected: index == current,
              // Un second appui sur l'onglet actif revient à sa racine.
              onTap: () => navigationShell.goBranch(
                index,
                initialLocation: index == current,
              ),
            ),
        ],
      ),
    );
  }
}

/// Barre basse des maquettes : filet supérieur, pas d'indicateur en pilule.
class _NavigationBar extends StatelessWidget {
  const _NavigationBar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
          child: Row(children: children),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.primary : colors.inkTertiary;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        excludeSemantics: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 3,
                children: [
                  Icon(icon, size: 24, color: color),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
