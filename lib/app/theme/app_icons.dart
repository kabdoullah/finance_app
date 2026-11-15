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
  static const archive = IconData(0xe00c, fontFamily: _regular);
  static const arrowCounterClockwise = IconData(0xe038, fontFamily: _regular);
  static const trash = IconData(0xe4a6, fontFamily: _regular);

  // Types de compte.
  static const money = IconData(0xe588, fontFamily: _regular);
  static const deviceMobile = IconData(0xe1e0, fontFamily: _regular);
  static const bank = IconData(0xe0b4, fontFamily: _regular);
  static const piggyBank = IconData(0xea04, fontFamily: _regular);
}
