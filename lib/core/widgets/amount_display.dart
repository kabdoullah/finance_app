import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../l10n/l10n.dart';
import '../money/money.dart';

/// Grand montant des maquettes : chiffres en gras, « FCFA » plus petit à côté.
class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    required this.amount,
    this.fontSize = 42,
    this.color,
    this.currencyColor,
    this.masked = false,
    super.key,
  });

  final Money amount;
  final double fontSize;
  final Color? color;
  final Color? currencyColor;

  /// Montant remplacé par « •••• ».
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = masked
        ? MoneyFormat.masked
        : amount.isNegative
        ? MoneyFormat.signed(amount)
        : MoneyFormat.amount(amount);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: 8,
      children: [
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.amount(fontSize).copyWith(
              color: amount.isNegative ? colors.negative : color ?? colors.ink,
            ),
          ),
        ),
        Text(
          context.l10n.currencyLabel,
          style: AppText.subtitle.copyWith(
            color: currencyColor ?? colors.inkSecondary,
          ),
        ),
      ],
    );
  }
}
