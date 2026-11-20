import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// Splash animé de Finao (2,1 s), posé au-dessus de [next] puis effacé
/// par un fondu croisé.
///
/// Chronologie (ms) : galet de base 0–320 · milieu 160–480 · sommet ambre
/// 320–700 · mot « Finao » 620–920 · logo complet affiché 0,8 s · fondu
/// croisé vers l'app 1800–2100.
/// « Réduire les animations » : position finale d'emblée, puis fondu simple.
///
/// [next] reste monté au même endroit du début à la fin (l'état de l'écran
/// de verrouillage et du routeur est conservé quand le splash disparaît).
class FinaoSplash extends StatefulWidget {
  const FinaoSplash({
    super.key,
    required this.next,
    this.stonesAlreadyShown = false,
  });

  final Widget next;

  /// Android 12+ : le splash système affiche déjà le cairn, seul le mot
  /// apparaît (pas de saut entre le splash natif et celui-ci).
  final bool stonesAlreadyShown;

  @override
  State<FinaoSplash> createState() => _FinaoSplashState();
}

class _FinaoSplashState extends State<FinaoSplash>
    with SingleTickerProviderStateMixin {
  /// Temps pendant lequel le logo complet reste affiché avant le fondu.
  static const _hold = 800.0;
  static const _total = 1300.0 + _hold;
  static const _decelerate = Cubic(0, 0, 0.2, 1);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _total.round()),
  );
  bool _done = false;

  Animation<double> _interval(double from, double to, Curve curve) =>
      CurvedAnimation(
        parent: _controller,
        curve: Interval(from / _total, to / _total, curve: curve),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.status == AnimationStatus.dismissed) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 920 / _total;
      }
      _controller.forward().whenComplete(() {
        if (mounted) setState(() => _done = true);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _stone(
    String part,
    bool dark,
    double from,
    double to,
    double dy,
    Curve curve,
  ) {
    final asset =
        'assets/brand/vector/parts/finao-stone-$part-${dark ? 'dark' : 'light'}.svg';
    final t = widget.stonesAlreadyShown
        ? const AlwaysStoppedAnimation(1.0)
        : _interval(from, to, curve);
    return AnimatedBuilder(
      animation: t,
      builder: (_, child) => Opacity(
        opacity: t.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, dy * (1 - t.value)),
          child: child,
        ),
      ),
      child: SvgPicture.asset(asset),
    );
  }

  Widget _splash(BuildContext context) {
    // Suit le thème du système, comme le splash natif qu'il prolonge (et non
    // le thème forcé dans les Paramètres).
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final background = dark ? const Color(0xFF174D3A) : const Color(0xFFF3F0E8);
    // Même échelle que le splash natif (portrait), sur le plus petit côté
    // pour tenir aussi en paysage.
    final width = MediaQuery.sizeOf(context).shortestSide * 0.36;
    final word = _interval(620, 920, _decelerate);
    final out = _interval(1000 + _hold, _total, const Cubic(0.4, 0, 1, 1));

    final splash = ColoredBox(
      color: background,
      child: Align(
        // Centre optique à 46 % de la hauteur.
        alignment: const Alignment(0, -0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: width,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _stone('base', dark, 0, 320, 6, _decelerate),
                  _stone('mid', dark, 160, 480, -8, _decelerate),
                  _stone('top', dark, 320, 700, -10, const Cubic(0.2, 0, 0, 1)),
                ],
              ),
            ),
            SizedBox(height: width * 0.04),
            AnimatedBuilder(
              animation: word,
              builder: (_, child) => Opacity(
                opacity: word.value,
                child: Transform.translate(
                  offset: Offset(0, 6 * (1 - word.value)),
                  child: child,
                ),
              ),
              child: SvgPicture.asset(
                'assets/brand/vector/finao-wordmark-${dark ? 'dark' : 'light'}.svg',
                width: width * 0.78,
                semanticsLabel: 'Finao',
              ),
            ),
          ],
        ),
      ),
    );

    return AnimatedBuilder(
      animation: out,
      builder: (_, child) => IgnorePointer(
        ignoring: out.value > 0,
        child: Opacity(
          opacity: 1 - out.value,
          child: Transform.scale(scale: 1 + 0.015 * out.value, child: child),
        ),
      ),
      child: splash,
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      FadeTransition(
        opacity: _done
            ? const AlwaysStoppedAnimation(1.0)
            : _interval(960 + _hold, 1260 + _hold, _decelerate),
        child: ExcludeSemantics(excluding: !_done, child: widget.next),
      ),
      if (!_done) _splash(context),
    ],
  );
}
