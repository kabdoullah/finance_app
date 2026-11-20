import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/motion.dart';

/// Sélecteur segmenté des maquettes : fond pastille, segment actif en surface.
class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.chip,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          spacing: 2,
          children: [
            for (final (value, label) in options)
              Expanded(
                child: _Segment(
                  label: label,
                  selected: value == selected,
                  onTap: () => onChanged(value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(9);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.surface : Colors.transparent,
        borderRadius: radius,
        elevation: selected ? 0.5 : 0,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: radius,
          onTap: () {
            if (!selected) Haptics.selection();
            onTap();
          },
          child: SizedBox(
            height: 36,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? colors.ink : colors.inkSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
