import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/money/money.dart';
import '../../../l10n/l10n.dart';
import '../domain/account.dart';
import 'account_labels.dart';

/// Choix d'un compte actif (formulaire d'opération). Retourne son id.
Future<String?> showAccountPicker(
  BuildContext context, {
  required List<Account> accounts,
  String? selectedId,
}) => showModalBottomSheet<String>(
  context: context,
  useRootNavigator: true,
  showDragHandle: true,
  backgroundColor: context.colors.surface,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
  ),
  builder: (sheetContext) {
    final colors = sheetContext.colors;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              sheetContext.l10n.txChooseAccount,
              style: AppText.sheetTitle,
            ),
          ),
          for (final account in accounts)
            InkWell(
              onTap: () => Navigator.of(sheetContext).pop(account.id),
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
                      child: Icon(account.type.icon, size: 18),
                    ),
                    Expanded(
                      child: Text(
                        account.name,
                        style: AppText.bodyLarge.semibold,
                      ),
                    ),
                    Text(
                      MoneyFormat.amount(account.balance),
                      style: AppText.body.copyWith(color: colors.inkSecondary),
                    ),
                    if (account.id == selectedId)
                      Icon(AppIcons.checkBold, size: 16, color: colors.primary)
                    else
                      const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  },
);
