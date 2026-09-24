import 'dart:math' as math;

import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// 250° horseshoe yay — alt açık, ilerleme sol uçtan başlar.
///
/// [Stack] içinde kullanılır; kendisi [Positioned] döner.
final class HorseshoeArc extends StatelessWidget {
  const HorseshoeArc({
    required this.progress,
    this.diameter = diameterDefault,
    this.progressColor = ColorName.colorMealPositive,
    this.trackColor = ColorName.colorPlanFasting,
    this.minProgress = 0.05,
    super.key,
  });

  final double progress;
  final double diameter;
  final Color progressColor;
  final Color trackColor;

  /// 0 iken yay hiç çizilmez; plan ekranı 0.05 ile küçük bir uç bırakır.
  final double minProgress;

  static const diameterDefault = 300.0;
  static const stroke = 28.0;
  static const sweepDegrees = 235.0;

  static const double _sweepRad = sweepDegrees * math.pi / 180;
  static const double _gapRad = (360 - sweepDegrees) * math.pi / 180;

  /// Flutter: 0=sağ, saat yönü pozitif. Alt merkez = π/2.
  static const double startRad = (math.pi / 2) + (_gapRad / 2);

  /// Yay ucunun daire sol/sağ kenarından uzaklığı.
  static double endpointInset(double diameter) {
    final radius = (diameter - stroke) / 2;
    return (diameter / 2) + radius * math.cos(startRad);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: diameter + 5,
      child: CustomPaint(
        painter: _HorseshoeArcPainter(
          progress: progress,
          stroke: stroke,
          sweepRad: _sweepRad,
          startRad: startRad,
          progressColor: progressColor,
          trackColor: trackColor,
          minProgress: minProgress,
        ),
      ),
    );
  }
}

final class _HorseshoeArcPainter extends CustomPainter {
  const _HorseshoeArcPainter({
    required this.progress,
    required this.stroke,
    required this.sweepRad,
    required this.startRad,
    required this.progressColor,
    required this.trackColor,
    required this.minProgress,
  });

  final double progress;
  final double stroke;
  final double sweepRad;
  final double startRad;
  final Color progressColor;
  final Color trackColor;
  final double minProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 4
      ..strokeCap = StrokeCap.round
      ..color = ColorName.colorPlanArcTrack;

    canvas.drawArc(rect, startRad, sweepRad, false, trackPaint);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    canvas.drawArc(rect, startRad, sweepRad, false, basePaint);

    if (progress <= 0) return;

    final progressSweep = sweepRad * progress.clamp(minProgress, 0.95);
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 4
      ..strokeCap = StrokeCap.round
      ..color = progressColor;

    canvas.drawArc(rect, startRad, progressSweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _HorseshoeArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.stroke != stroke ||
        oldDelegate.sweepRad != sweepRad ||
        oldDelegate.startRad != startRad ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.minProgress != minProgress;
  }
}
