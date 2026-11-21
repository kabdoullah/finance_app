import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';

/// Libellé au-dessus d'un champ de formulaire (« Nom du compte »).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: AppText.label.medium.copyWith(color: context.colors.inkSecondary),
    ),
  );
}
