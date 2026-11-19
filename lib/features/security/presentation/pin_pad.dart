import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../l10n/l10n.dart';
import '../domain/pin_policy.dart';

/// Saisie d'un code à 4 chiffres : points, message, pavé numérique.
/// [onComplete] reçoit le code dès le 4e chiffre ; le pavé se vide ensuite.
class PinPad extends StatefulWidget {
  const PinPad({
    required this.title,
    required this.onComplete,
    this.message,
    this.messageIsError = false,
    this.enabled = true,
    this.onBiometric,
    this.footer,
    super.key,
  });

  final String title;
  final String? message;
  final bool messageIsError;
  final bool enabled;
  final Future<void> Function(String pin) onComplete;

  /// Bouton empreinte ou visage (en bas à gauche du pavé).
  final VoidCallback? onBiometric;
  final Widget? footer;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  bool _busy = false;

  Future<void> _digit(String digit) async {
    if (_busy || !widget.enabled || _pin.length >= PinPolicy.length) return;
    setState(() => _pin += digit);
    if (_pin.length < PinPolicy.length) return;
    _busy = true;
    try {
      await widget.onComplete(_pin);
    } finally {
      _busy = false;
      if (mounted) setState(() => _pin = '');
    }
  }

  void _delete() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    Widget key(Widget child, {VoidCallback? onTap, String? label}) => Semantics(
      button: true,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 72, height: 72, child: Center(child: child)),
      ),
    );
    Widget digit(String d) => key(
      Text(
        d,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
      ),
      onTap: widget.enabled ? () => _digit(d) : null,
      label: d,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            for (var i = 0; i < PinPolicy.length; i++)
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? colors.ink : Colors.transparent,
                  border: Border.all(color: colors.inkSecondary, width: 1.5),
                ),
              ),
          ],
        ),
        SizedBox(
          height: 56,
          child: Center(
            child: widget.message == null
                ? null
                : Text(
                    widget.message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.messageIsError
                          ? colors.negative
                          : colors.inkSecondary,
                    ),
                  ),
          ),
        ),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 20,
            children: [for (final d in row) digit(d)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 20,
          children: [
            if (widget.onBiometric case final onBiometric?)
              key(
                Icon(AppIcons.fingerprint, size: 28, color: colors.ink),
                onTap: onBiometric,
                label: l10n.lockBiometricButton,
              )
            else
              const SizedBox(width: 72, height: 72),
            digit('0'),
            key(
              Icon(AppIcons.backspace, size: 26, color: colors.ink),
              onTap: _delete,
              label: l10n.lockDelete,
            ),
          ],
        ),
        if (widget.footer case final footer?) ...[
          const SizedBox(height: 12),
          footer,
        ],
      ],
    );
  }
}
