import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import '../../app/theme/motion.dart';

/// Apparition d'une cascade : 8 px vers le haut + fondu, décalée de
/// [index] × 40 ms (6 au maximum). Une seule fois, à la construction.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({required this.child, this.index = 0, super.key});

  final Widget child;
  final int index;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late Animation<double> _progress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null || Motion.reduced(context)) return;
    // Le décalage fait partie de l'animation : aucun minuteur en attente.
    final delay =
        Motion.stagger * widget.index.clamp(0, Motion.maxStagger).toInt();
    final total = delay + Motion.slow;
    final controller = _controller = AnimationController(
      vsync: this,
      duration: total,
    );
    _progress = CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Motion.easeOut,
      ),
    );
    controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) return widget.child;
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) => Opacity(
        opacity: _progress.value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - _progress.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Montant qui compte : à l'apparition de 92 % à 100 % de [value] en
/// [firstDuration], puis de l'ancienne à la nouvelle valeur en
/// [duration].
class CountingValue extends StatefulWidget {
  const CountingValue({
    required this.value,
    required this.builder,
    this.firstDuration = Motion.chart,
    this.duration = Motion.count,
    super.key,
  });

  final int value;
  final Widget Function(BuildContext context, int value) builder;
  final Duration firstDuration;
  final Duration duration;

  @override
  State<CountingValue> createState() => _CountingValueState();
}

class _CountingValueState extends State<CountingValue> {
  late int _from = (widget.value * Motion.countFrom).round();
  bool _first = true;

  @override
  void didUpdateWidget(CountingValue old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = old.value;
      _first = false;
    }
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    // Une nouvelle cible relance l'animation depuis [_from].
    key: ValueKey(widget.value),
    tween: Tween(begin: _from.toDouble(), end: widget.value.toDouble()),
    duration: Motion.of(
      context,
      _first ? widget.firstDuration : widget.duration,
    ),
    curve: Motion.ease,
    builder: (context, value, _) => widget.builder(context, value.round()),
  );
}

/// Fraction qui se remplit depuis zéro (barres).
class FillIn extends StatelessWidget {
  const FillIn({
    required this.value,
    required this.builder,
    this.duration = Motion.fill,
    super.key,
  });

  final double value;
  final Widget Function(BuildContext context, double value) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value),
    duration: Motion.of(context, duration),
    curve: Motion.ease,
    builder: (context, v, _) => builder(context, v),
  );
}

/// Ligne pressée : légèrement réduite (98 %) pendant l'appui.
class PressScale extends StatefulWidget {
  const PressScale({required this.child, super.key});

  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: Motion.of(context, Motion.fast),
      curve: Motion.ease,
      child: widget.child,
    ),
  );
}

/// Passage entre deux contenus : fondu et flou de 6 px (montants masqués).
class BlurFadeSwitcher extends StatelessWidget {
  const BlurFadeSwitcher({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: Motion.of(context, Motion.base),
    switchInCurve: Motion.ease,
    switchOutCurve: Motion.easeIn,
    layoutBuilder: (current, previous) => Stack(
      alignment: Alignment.centerLeft,
      children: [...previous, ?current],
    ),
    transitionBuilder: (child, animation) => AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final sigma = 6 * (1 - animation.value);
        return Opacity(
          opacity: animation.value,
          child: sigma < 0.01
              ? child
              : ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: child,
                ),
        );
      },
      child: child,
    ),
    child: child,
  );
}
