import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_icons.dart';

const _icons = {
  'basket': AppIcons.basket,
  'taxi': AppIcons.taxi,
  'house-line': AppIcons.houseLine,
  'receipt': AppIcons.receipt,
  'ticket': AppIcons.ticket,
  'heartbeat': AppIcons.heartbeat,
  'users': AppIcons.users,
  'hand-coins': AppIcons.handCoins,
  'graduation-cap': AppIcons.graduationCap,
  't-shirt': AppIcons.tShirt,
  'dots-three': AppIcons.dotsThree,
  'money': AppIcons.money,
  'tag': AppIcons.tag,
  'gift': AppIcons.gift,
  'device-mobile': AppIcons.deviceMobile,
  'arrow-down-left': AppIcons.arrowDownLeft,
};

/// Icône d'une catégorie à partir de sa clé en base.
IconData categoryIcon(String key) => _icons[key] ?? AppIcons.tag;
