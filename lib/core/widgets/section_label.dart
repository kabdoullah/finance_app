import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';

/// Surtitre d'un groupe de réglages, en majuscules (« SÉCURITÉ »).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 4),
    child: Text(
      label.toUpperCase(),
      style: AppText.overline.copyWith(color: context.colors.inkTertiary),
    ),
  );
}
