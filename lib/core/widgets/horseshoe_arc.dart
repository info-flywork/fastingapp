import 'dart:math' as math;

import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// 250° horseshoe yay — alt açık, ilerleme sol uçtan başlar.
///
/// [Stack] içinde kullanılır; kendisi [Positioned] döner.
final class HorseshoeArc extends StatelessWidget {
  const HorseshoeArc({
    required this.progress,
    this.start = 0,
    this.diameter = diameterDefault,
    this.progressColor = ColorName.colorMealPositive,
    this.trackColor = ColorName.colorPlanFasting,
    this.minProgress = 0.05,
    super.key,
  });

  final double progress;

  /// İlerlemenin yay üzerindeki başlangıcı (0 = sol uç, 1 = sağ uç).
  /// Plan detayında yeme penceresinin gün içindeki yeri.
  final double start;
  final double diameter;
  final Color progressColor;
  final Color trackColor;

  /// 0 iken yay hiç çizilmez; plan ekranı 0.05 ile küçük bir uç bırakır.
  final double minProgress;

  static const diameterDefault = 300.0;
  static const stroke = 28.0;

  /// İz ve ilerleme konturu `stroke`tan bu kadar kalın çizilir.
  static const strokeExtra = 4.0;
  static const sweepDegrees = 235.0;

  static const double _sweepRad = sweepDegrees * math.pi / 180;
  static const double _gapRad = (360 - sweepDegrees) * math.pi / 180;

  /// Flutter: 0=sağ, saat yönü pozitif. Alt merkez = π/2.
  static const double startRad = (math.pi / 2) + (_gapRad / 2);

  /// En kalın konturun dış kenarı tuvalin içinde kalsın (yanlar kesilmesin).
  static double radiusFor(Size size) {
    final outer = stroke + strokeExtra;
    return (math.min(size.width, size.height) - outer) / 2 - 0.5;
  }

  /// Yay ucunun daire sol/sağ kenarından uzaklığı.
  static double endpointInset(double diameter) {
    final radius = radiusFor(Size(diameter, diameter));
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
          start: start,
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
    required this.start,
    required this.stroke,
    required this.sweepRad,
    required this.startRad,
    required this.progressColor,
    required this.trackColor,
    required this.minProgress,
  });

  final double progress;
  final double start;
  final double stroke;
  final double sweepRad;
  final double startRad;
  final Color progressColor;
  final Color trackColor;
  final double minProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = HorseshoeArc.radiusFor(size);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + HorseshoeArc.strokeExtra
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

    // 1.0 = yay ucuna kadar dolu (önceden 0.95 kesiliyordu → "tamamlandı"
    // halinde at nalı eksik görünüyordu).
    final length = progress.clamp(minProgress, 1.0);
    final from = start.clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + HorseshoeArc.strokeExtra
      ..strokeCap = StrokeCap.round
      ..color = progressColor;

    final end = from + length;
    if (end <= 1) {
      canvas.drawArc(
        rect,
        startRad + sweepRad * from,
        sweepRad * length,
        false,
        progressPaint,
      );
      return;
    }
    // Pencere gece yarısını aşıyorsa sağ uçtan sol uca devam eder.
    final head = 1 - from;
    canvas
      ..drawArc(
        rect,
        startRad + sweepRad * from,
        sweepRad * head,
        false,
        progressPaint,
      )
      ..drawArc(
        rect,
        startRad,
        sweepRad * (end - 1),
        false,
        progressPaint,
      );
  }

  @override
  bool shouldRepaint(covariant _HorseshoeArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.start != start ||
        oldDelegate.stroke != stroke ||
        oldDelegate.sweepRad != sweepRad ||
        oldDelegate.startRad != startRad ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.minProgress != minProgress;
  }
}
