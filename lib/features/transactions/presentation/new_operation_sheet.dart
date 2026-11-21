import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/motion.dart';
import '../../../l10n/l10n.dart';

/// Ouvre l'écran « Nouvelle opération » (type, montant, raccourcis
/// « Dicter » et « Écrire avec mes mots »).
void openNewOperation(BuildContext context) =>
    context.push(AppRoutes.newTransaction());

/// Boutons flottants du design system, toujours au même endroit : « + »
/// (saisie à la main, ouvre l'écran Nouvelle opération) et « Dicter », le
/// principal (la voix est privilégiée).
class AddOperationButton extends StatelessWidget {
  const AddOperationButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        FloatingActionButton(
          heroTag: 'add-operation',
          tooltip: l10n.txAdd,
          backgroundColor: colors.surface,
          foregroundColor: colors.ink,
          onPressed: () => openNewOperation(context),
          child: const Icon(AppIcons.plusBold, size: 20),
        ),
        FloatingActionButton.extended(
          heroTag: 'dictate',
          onPressed: () => context.push(AppRoutes.quickEntry()),
          icon: const Icon(AppIcons.microphoneBold, size: 18),
          label: Text(l10n.txEmptyDictate),
        ),
      ],
    );
  }
}

/// Écran à onglet portant [AddOperationButton] : les boutons glissent hors
/// de l'écran quand on fait défiler vers le bas, pour ne pas cacher montants
/// et légendes, et reviennent dès qu'on remonte.
class AddOperationScaffold extends StatefulWidget {
  const AddOperationScaffold({
    required this.body,
    this.showButton = true,
    super.key,
  });

  final Widget body;
  final bool showButton;

  @override
  State<AddOperationScaffold> createState() => _AddOperationScaffoldState();
}

class _AddOperationScaffoldState extends State<AddOperationScaffold> {
  var _visible = true;

  bool _onScroll(UserScrollNotification notification) {
    // Défilement principal seulement (pas les bandeaux horizontaux).
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final visible = switch (notification.direction) {
      ScrollDirection.reverse => false,
      ScrollDirection.forward => true,
      ScrollDirection.idle => _visible,
    };
    if (visible != _visible) setState(() => _visible = visible);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.showButton
          ? AnimatedSlide(
              offset: _visible ? Offset.zero : const Offset(0, 2),
              duration: Motion.of(context, Motion.base),
              curve: _visible ? Motion.easeOut : Motion.easeIn,
              child: IgnorePointer(
                ignoring: !_visible,
                child: ExcludeSemantics(
                  excluding: !_visible,
                  child: const AddOperationButton(),
                ),
              ),
            )
          : null,
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onScroll,
        child: widget.body,
      ),
    );
  }
}
