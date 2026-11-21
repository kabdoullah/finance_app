import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/motion.dart';

/// Pilule de choix des maquettes (catégories, opérateurs, comptes) :
/// fond sauge et bord forêt quand elle est sélectionnée.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.leading,
    this.height = 38,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// Petit repère avant le libellé (pastille de statut), à la place de
  /// [icon].
  final Widget? leading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.onPrimarySoft : colors.ink;
    final shape = StadiumBorder(
      side: BorderSide(color: selected ? colors.primary : colors.line),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.primarySoft : colors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: () {
            Haptics.selection();
            onTap();
          },
          child: SizedBox(
            height: height,
            child: Padding(
              padding: EdgeInsets.only(
                left: icon == null && leading == null ? 14 : 12,
                right: 14,
              ),
              // `widthFactor: 1` : la pilule épouse son contenu.
              child: Center(
                widthFactor: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    ?leading,
                    if (icon != null) Icon(icon, size: 17, color: foreground),
                    Text(
                      label,
                      style: AppText.bodySmall.semibold.copyWith(
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
