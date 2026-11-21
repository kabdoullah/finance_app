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

/// Coche qui se trace (360 ms) : opération ou budget enregistré.
class DrawnCheck extends StatelessWidget {
  static const _duration = Duration(milliseconds: 360);

  const DrawnCheck({required this.color, this.size = 32, super.key});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Motion.of(context, _duration),
    curve: Motion.ease,
    builder: (context, progress, _) => CustomPaint(
      size: Size.square(size),
      painter: _CheckPainter(progress: progress, color: color),
    ),
  );
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.53)
      ..lineTo(size.width * 0.42, size.height * 0.74)
      ..lineTo(size.width * 0.8, size.height * 0.3);
    final metric = path.computeMetrics().single;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.color != color;
}

/// Deux anneaux qui s'élargissent autour de [child] tant que [active]
/// (écoute de la dictée, boucle de 1,8 s).
class PulseRings extends StatefulWidget {
  const PulseRings({
    required this.active,
    required this.color,
    required this.child,
    this.size = 88,
    super.key,
  });

  final bool active;
  final Color color;
  final double size;
  final Widget child;

  @override
  State<PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<PulseRings>
    with SingleTickerProviderStateMixin {
  static const _cycle = Duration(milliseconds: 1800);

  late final _controller = AnimationController(vsync: this, duration: _cycle);

  void _sync() {
    if (widget.active && !Motion.reduced(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PulseRings old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size * 1.8,
    child: Stack(
      alignment: Alignment.center,
      children: [
        if (widget.active)
          for (final offset in const [0.0, 0.5])
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = (_controller.value + offset) % 1;
                return Container(
                  width: widget.size * (1 + 0.8 * t),
                  height: widget.size * (1 + 0.8 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 2,
                      color: widget.color.withValues(alpha: 0.5 * (1 - t)),
                    ),
                  ),
                );
              },
            ),
        widget.child,
      ],
    ),
  );
}

/// Trois points qui s'animent pendant un calcul (boucle de 1,2 s).
class TypingDots extends StatefulWidget {
  const TypingDots({required this.color, super.key});

  final Color color;

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  static const _cycle = Duration(milliseconds: 1200);

  late final _controller = AnimationController(vsync: this, duration: _cycle);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        for (var i = 0; i < 3; i++)
          Opacity(
            opacity: 0.3 + 0.7 * _pulse((_controller.value - i * 0.18) % 1),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ),
      ],
    ),
  );

  /// 0 → 1 → 0 sur la première moitié du cycle.
  static double _pulse(double t) => t < 0.5 ? 1 - (2 * t - 1).abs() : 0;
}

/// Halo ambre unique quand [reached] passe à vrai pendant l'affichage
/// (objectif atteint, 900 ms) ; jamais à l'ouverture d'un objectif déjà
/// atteint.
class ReachedHalo extends StatefulWidget {
  const ReachedHalo({
    required this.reached,
    required this.color,
    required this.child,
    this.onReached,
    super.key,
  });

  final bool reached;
  final Color color;
  final Widget child;
  final VoidCallback? onReached;

  @override
  State<ReachedHalo> createState() => _ReachedHaloState();
}

class _ReachedHaloState extends State<ReachedHalo>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 900);

  late final _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );

  @override
  void didUpdateWidget(ReachedHalo old) {
    super.didUpdateWidget(old);
    if (widget.reached && !old.reached) {
      widget.onReached?.call();
      if (!Motion.reduced(context)) _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final t = _controller.value;
      final visible = _controller.isAnimating;
      return Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (visible)
            Transform.scale(
              scale: 1 + 0.6 * Motion.easeOut.transform(t),
              child: Opacity(
                opacity: 0.5 * (1 - t),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                  ),
                  child: Opacity(opacity: 0, child: child),
                ),
              ),
            ),
          child!,
        ],
      );
    },
    child: widget.child,
  );
}
