import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/motion.dart';
import '../../../core/widgets/motion.dart';
import '../domain/forecast.dart';

/// Graphique de la maquette Prévisions : passé (trait plein), estimation
/// (pointillés), fourchette probable (bande), ligne zéro, repère
/// « Aujourd'hui » et points de vigilance.
class ForecastChart extends StatelessWidget {
  const ForecastChart({
    required this.forecast,
    required this.semanticLabel,
    this.height = 150,
    super.key,
  });

  final Forecast forecast;
  final String semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      image: true,
      label: semanticLabel,
      child: SizedBox(
        height: height,
        width: double.infinity,
        // Tracé de gauche à droite à l'apparition.
        child: FillIn(
          value: 1,
          duration: Motion.chart,
          // L'Align extérieur libère la largeur : seule la part tracée est
          // visible.
          builder: (context, progress) => Align(
            alignment: Alignment.centerLeft,
            child: ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: SizedBox(
                  height: height,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _ForecastPainter(
                      forecast: forecast,
                      colors: colors,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ForecastPainter extends CustomPainter {
  _ForecastPainter({required this.forecast, required this.colors});

  final Forecast forecast;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final past = forecast.history;
    final points = forecast.points;
    final back = past.length - 1;
    final days = points.length - 1;
    final bands = [for (var d = 0; d <= days; d++) forecast.bandAt(d)];

    final values = <double>[
      0,
      for (final p in past) p.value.toDouble(),
      for (var d = 0; d <= days; d++) ...[
        points[d].value - bands[d],
        points[d].value + bands[d],
      ],
    ];
    final low = values.reduce(math.min);
    var high = values.reduce(math.max);
    if (high - low < 1) high = low + 1;
    const top = 10.0;
    final bottom = size.height - 10;

    double x(int d) => (d + back) / (days + back) * size.width;
    double y(num v) => top + (high - v) / (high - low) * (bottom - top);

    // Fourchette probable.
    final band = Path()..moveTo(x(0), y(points[0].value + bands[0]));
    for (var d = 1; d <= days; d++) {
      band.lineTo(x(d), y(points[d].value + bands[d]));
    }
    for (var d = days; d >= 0; d--) {
      band.lineTo(x(d), y(points[d].value - bands[d]));
    }
    band.close();
    canvas.drawPath(band, Paint()..color = colors.primarySoft);

    // Ligne zéro.
    canvas.drawLine(
      Offset(0, y(0)),
      Offset(size.width, y(0)),
      Paint()
        ..color = colors.line
        ..strokeWidth = 1,
    );

    // Repère « Aujourd'hui ».
    _dashedLine(
      canvas,
      Offset(x(0), 0),
      Offset(x(0), size.height - 4),
      Paint()
        ..color = colors.inkTertiary
        ..strokeWidth = 1,
    );

    // Passé.
    final history = Path()..moveTo(x(-back), y(past.first.value));
    for (var k = 1; k <= back; k++) {
      history.lineTo(x(k - back), y(past[k].value));
    }
    canvas.drawPath(
      history,
      Paint()
        ..color = colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.75
        ..strokeJoin = StrokeJoin.round,
    );

    // Estimation (pointillés).
    final estimate = Path()..moveTo(x(0), y(points[0].value));
    for (var d = 1; d <= days; d++) {
      estimate.lineTo(x(d), y(points[d].value));
    }
    _dashedPath(
      canvas,
      estimate,
      Paint()
        ..color = colors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    // Points de vigilance.
    final markers = <int>[
      if (forecast.negativeOn case final date?) _dayIndex(date),
      if (forecast.lowBalance case final risk?) _dayIndex(risk.date),
    ];
    for (final d in markers) {
      final center = Offset(x(d), y(points[d].value));
      canvas
        ..drawCircle(center, 6, Paint()..color = colors.background)
        ..drawCircle(center, 4.5, Paint()..color = colors.warning);
    }
  }

  int _dayIndex(DateTime date) => (date.difference(forecast.today).inHours / 24)
      .round()
      .clamp(0, forecast.points.length - 1);

  static void _dashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 2.0;
    const gap = 3.0;
    final total = (to - from).distance;
    final direction = (to - from) / total;
    for (var t = 0.0; t < total; t += dash + gap) {
      canvas.drawLine(
        from + direction * t,
        from + direction * math.min(t + dash, total),
        paint,
      );
    }
  }

  static void _dashedPath(Canvas canvas, Path path, Paint paint) {
    const dash = 4.0;
    const gap = 3.0;
    for (final ui.PathMetric metric in path.computeMetrics()) {
      for (var t = 0.0; t < metric.length; t += dash + gap) {
        canvas.drawPath(
          metric.extractPath(t, math.min(t + dash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ForecastPainter old) =>
      old.forecast != forecast || old.colors != colors;
}
