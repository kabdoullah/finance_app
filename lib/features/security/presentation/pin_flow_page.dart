import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../domain/pin_policy.dart';
import 'lock_controller.dart';
import 'pin_pad.dart';

/// Ce que l'écran de code doit faire.
enum PinFlow { create, change, disable }

enum _Step { current, choose, confirm }

/// Activer le verrouillage (choisir puis confirmer), changer le code
/// (code actuel, nouveau, confirmation) ou le désactiver (code actuel).
/// Se ferme avec `true` en cas de succès.
class PinFlowPage extends ConsumerStatefulWidget {
  const PinFlowPage({required this.flow, super.key});

  final PinFlow flow;

  @override
  ConsumerState<PinFlowPage> createState() => _PinFlowPageState();
}

class _PinFlowPageState extends ConsumerState<PinFlowPage> {
  late _Step _step = widget.flow == PinFlow.create
      ? _Step.choose
      : _Step.current;
  String? _chosen;
  String? _message;
  bool _error = false;

  LockController get _controller => ref.read(lockControllerProvider.notifier);

  Future<void> _submit(String pin) async {
    final l10n = context.l10n;
    switch (_step) {
      case _Step.current:
        final check = await _controller.verify(pin);
        if (!mounted) return;
        if (check != PinCheck.ok) {
          final wait = _controller.remainingWait();
          setState(() {
            _error = true;
            _message = wait != null
                ? l10n.lockWait('${(wait.inSeconds + 59) ~/ 60} min')
                : l10n.lockWrong(
                    PinPolicy.remainingBeforeWait(
                      ref.read(lockControllerProvider).failures,
                    ),
                  );
          });
          return;
        }
        if (widget.flow == PinFlow.disable) {
          await _controller.disable();
          return _done(l10n.pinDisabled);
        }
        setState(() {
          _step = _Step.choose;
          _message = null;
          _error = false;
        });
      case _Step.choose:
        setState(() {
          _chosen = pin;
          _step = _Step.confirm;
          _message = null;
          _error = false;
        });
      case _Step.confirm:
        if (pin != _chosen) {
          setState(() {
            _chosen = null;
            _step = _Step.choose;
            _error = true;
            _message = l10n.pinMismatch;
          });
          return;
        }
        await _controller.setPin(pin);
        _done(
          widget.flow == PinFlow.create ? l10n.pinEnabled : l10n.pinChanged,
        );
    }
  }

  void _done(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final title = switch (_step) {
      _Step.current => l10n.pinCurrentTitle,
      _Step.choose =>
        widget.flow == PinFlow.create ? l10n.pinCreateTitle : l10n.pinNewTitle,
      _Step.confirm => l10n.pinConfirmTitle,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsLock)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (widget.flow == PinFlow.create && _step == _Step.choose) ...[
                  Text(
                    l10n.pinCreateHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: colors.inkSecondary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.warningSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      l10n.pinCreateWarning,
                      style: const TextStyle(fontSize: 13.5, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                PinPad(
                  // Nouvelle saisie à chaque étape.
                  key: ValueKey(_step),
                  title: title,
                  message: _message,
                  messageIsError: _error,
                  onComplete: (pin) => _submit(pin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
