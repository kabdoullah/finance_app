import 'package:material_ui/material_ui.dart';

/// Icônes Phosphor 2.1.2 embarquées (assets/fonts), mêmes codepoints que les
/// maquettes. On n'ajoute une icône ici qu'au moment où un écran l'utilise.
abstract final class AppIcons {
  static const _regular = 'Phosphor';
  static const _fill = 'PhosphorFill';
  static const _bold = 'PhosphorBold';

  // Navigation (variante pleine = onglet actif).
  static const house = IconData(0xe2c2, fontFamily: _regular);
  static const houseFill = IconData(0xe2c2, fontFamily: _fill);
  static const arrowsDownUp = IconData(0xe098, fontFamily: _regular);
  static const arrowsDownUpFill = IconData(0xe098, fontFamily: _fill);
  static const chartDonut = IconData(0xeaa6, fontFamily: _regular);
  static const chartDonutFill = IconData(0xeaa6, fontFamily: _fill);
  static const chartLine = IconData(0xe154, fontFamily: _regular);
  static const chartLineFill = IconData(0xe154, fontFamily: _fill);
  static const chatCircleText = IconData(0xe16e, fontFamily: _regular);
  static const chatCircleTextFill = IconData(0xe16e, fontFamily: _fill);

  // Interface.
  static const caretRight = IconData(0xe13a, fontFamily: _regular);
  static const gearSix = IconData(0xe272, fontFamily: _regular);
  static const lockSimple = IconData(0xe308, fontFamily: _regular);
  static const caretLeftBold = IconData(0xe138, fontFamily: _bold);
  static const xBold = IconData(0xe4f6, fontFamily: _bold);
  static const plusBold = IconData(0xe3d4, fontFamily: _bold);
  static const checkBold = IconData(0xe182, fontFamily: _bold);
  static const checkCircleBold = IconData(0xe184, fontFamily: _bold);
  static const minusBold = IconData(0xe32a, fontFamily: _bold);
  static const umbrella = IconData(0xe684, fontFamily: _regular);
  static const airplane = IconData(0xe002, fontFamily: _regular);
  static const heart = IconData(0xe2a8, fontFamily: _regular);
  static const motorcycle = IconData(0xe80a, fontFamily: _regular);
  static const clockBold = IconData(0xe19a, fontFamily: _bold);
  static const repeatBold = IconData(0xe3f6, fontFamily: _bold);
  static const repeat = IconData(0xe3f6, fontFamily: _regular);
  static const play = IconData(0xe3d0, fontFamily: _regular);
  static const stop = IconData(0xe46c, fontFamily: _regular);
  static const warningCircleBold = IconData(0xe4e2, fontFamily: _bold);
  static const chartLineBold = IconData(0xe154, fontFamily: _bold);
  static const archive = IconData(0xe00c, fontFamily: _regular);
  static const arrowCounterClockwise = IconData(0xe038, fontFamily: _regular);
  static const trash = IconData(0xe4a6, fontFamily: _regular);

  static const caretDownBold = IconData(0xe136, fontFamily: _bold);
  static const arrowDownLeftBold = IconData(0xe040, fontFamily: _bold);
  static const arrowUpRightBold = IconData(0xe092, fontFamily: _bold);
  static const arrowDownLeft = IconData(0xe040, fontFamily: _regular);
  static const arrowUpRight = IconData(0xe092, fontFamily: _regular);
  static const arrowsLeftRight = IconData(0xe0a0, fontFamily: _regular);
  static const magnifyingGlass = IconData(0xe30c, fontFamily: _regular);
  static const calendarBlank = IconData(0xe10a, fontFamily: _regular);
  static const notePencil = IconData(0xe34c, fontFamily: _regular);
  static const copy = IconData(0xe1ca, fontFamily: _regular);
  static const backspace = IconData(0xe0ae, fontFamily: _regular);
  static const wallet = IconData(0xe68a, fontFamily: _regular);
  static const tray = IconData(0xe4aa, fontFamily: _regular);
  static const info = IconData(0xe2ce, fontFamily: _regular);

  // Catégories (clés de la table categories).
  static const basket = IconData(0xe964, fontFamily: _regular);
  static const taxi = IconData(0xe902, fontFamily: _regular);
  static const houseLine = IconData(0xe2c4, fontFamily: _regular);
  static const receipt = IconData(0xe3ec, fontFamily: _regular);
  static const ticket = IconData(0xe490, fontFamily: _regular);
  static const heartbeat = IconData(0xe2ac, fontFamily: _regular);
  static const users = IconData(0xe4d6, fontFamily: _regular);
  static const handCoins = IconData(0xea8c, fontFamily: _regular);
  static const graduationCap = IconData(0xe62c, fontFamily: _regular);
  static const tShirt = IconData(0xe670, fontFamily: _regular);
  static const dotsThree = IconData(0xe1fe, fontFamily: _regular);
  static const tag = IconData(0xe478, fontFamily: _regular);
  static const gift = IconData(0xe276, fontFamily: _regular);
  static const eyeSlash = IconData(0xe224, fontFamily: _regular);
  static const eye = IconData(0xe220, fontFamily: _regular);
  static const pencilSimple = IconData(0xe3b4, fontFamily: _regular);

  // Types de compte.
  static const money = IconData(0xe588, fontFamily: _regular);
  static const deviceMobile = IconData(0xe1e0, fontFamily: _regular);
  static const bank = IconData(0xe0b4, fontFamily: _regular);
  static const piggyBank = IconData(0xea04, fontFamily: _regular);
}
