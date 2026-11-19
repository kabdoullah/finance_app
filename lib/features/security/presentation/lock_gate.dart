import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../l10n/l10n.dart';
import '../domain/pin_policy.dart';
import 'lock_controller.dart';
import 'pin_pad.dart';

/// Recouvre l'application tant qu'elle est verrouillée (ou que les réglages
/// ne sont pas lus) ; l'application reste montée dessous, son état est
/// conservé. Placée dans `MaterialApp.builder`.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(lockControllerProvider.notifier);
    _lifecycle = AppLifecycleListener(
      onHide: controller.onHidden,
      onShow: controller.onResumed,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lockControllerProvider);
    final covered = !state.loaded || state.locked;
    ref.listen(lockControllerProvider.select((s) => s.locked), (_, locked) {
      if (locked) FocusManager.instance.primaryFocus?.unfocus();
    });
    return Stack(
      children: [
        ExcludeSemantics(
          excluding: covered,
          child: IgnorePointer(ignoring: covered, child: widget.child),
        ),
        if (!state.loaded)
          Positioned.fill(child: ColoredBox(color: context.colors.background))
        else if (state.locked)
          const Positioned.fill(child: _LockScreen()),
      ],
    );
  }
}

class _LockScreen extends ConsumerStatefulWidget {
  const _LockScreen();

  @override
  ConsumerState<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<_LockScreen> {
  String? _message;
  bool _error = false;
  bool _showForgot = false;
  Timer? _ticker;

  LockController get _controller => ref.read(lockControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    // Attente en cours, sinon empreinte ou visage proposés dès l'affichage.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshWait();
      unawaited(_biometric());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _biometric() async {
    if (!mounted || !ref.read(lockControllerProvider).biometric) return;
    if (_controller.remainingWait() != null) return;
    await _controller.unlockWithBiometrics(context.l10n.lockBiometricReason);
  }

  /// Message d'attente, rafraîchi chaque seconde.
  void _refreshWait() {
    final left = _controller.remainingWait();
    _ticker?.cancel();
    if (left == null) return;
    setState(() {
      _error = true;
      _message = context.l10n.lockWait(_formatWait(left));
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _controller.remainingWait();
      if (!mounted) return;
      if (remaining == null) {
        _ticker?.cancel();
        setState(() => _message = null);
      } else {
        setState(
          () => _message = context.l10n.lockWait(_formatWait(remaining)),
        );
      }
    });
  }

  static String _formatWait(Duration d) {
    final seconds = d.inSeconds + 1;
    if (seconds < 60) return '$seconds s';
    final minutes = (seconds / 60).ceil();
    return '$minutes min';
  }

  Future<void> _submit(String pin) async {
    final l10n = context.l10n;
    switch (await _controller.unlock(pin)) {
      case PinCheck.ok:
        return;
      case PinCheck.wrong:
        if (!mounted) return;
        setState(() {
          _error = true;
          _message = l10n.lockWrong(
            PinPolicy.remainingBeforeWait(
              ref.read(lockControllerProvider).failures,
            ),
          );
        });
      case PinCheck.waiting:
        if (mounted) _refreshWait();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final state = ref.watch(lockControllerProvider);
    final waiting = _ticker?.isActive ?? false;
    return Material(
      color: colors.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.lockKey, size: 36, color: colors.inkSecondary),
                const SizedBox(height: 8),
                Text(
                  l10n.appTitle,
                  style: TextStyle(fontSize: 14, color: colors.inkSecondary),
                ),
                const SizedBox(height: 16),
                PinPad(
                  title: l10n.lockEnter,
                  message: _message,
                  messageIsError: _error,
                  enabled: !waiting,
                  onComplete: _submit,
                  onBiometric: state.biometric && !waiting ? _biometric : null,
                  footer: TextButton(
                    onPressed: () => setState(() => _showForgot = !_showForgot),
                    child: Text(l10n.lockForgot),
                  ),
                ),
                if (_showForgot)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.lockForgotBody,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: colors.inkSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
