import 'dart:math' as math;

import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Ana ekran su widget'ı — 310 kare, tasarım ölçüsü.
final class WaterHomeWidgetView extends StatelessWidget {
  const WaterHomeWidgetView({
    required this.currentMl,
    required this.goalMl,
    required this.goalLabel,
    required this.unitLabel,
    super.key,
  });

  final int currentMl;
  final int goalMl;
  final String goalLabel;
  final String unitLabel;

  static const logicalSize = Size(310, 310);

  @override
  Widget build(BuildContext context) {
    final progress = goalMl <= 0 ? 0.0 : (currentMl / goalMl).clamp(0.0, 1.0);
    return SizedBox(
      width: 310,
      height: 310,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColorName.colorWhite,
          borderRadius: BorderRadius.circular(60),
          border: Border.all(color: ColorName.colorWaterRulerTick),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: _WaterRingPainter(progress: progress),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$currentMl', style: _amount),
                      Text(unitLabel, style: _unit),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(goalLabel, style: _goalLabel),
              const SizedBox(height: 2),
              Text('$goalMl $unitLabel', style: _goalValue),
            ],
          ),
        ),
      ),
    );
  }
}

const _amount = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 56,
  height: 64 / 56,
  letterSpacing: -0.7,
  color: ColorName.colorTitle,
);

final _unit = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 22,
  height: 28 / 22,
  letterSpacing: 22 * -0.015,
  color: ColorName.colorSubtitle.withValues(alpha: 0.6),
);

final _goalLabel = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 20,
  height: 26 / 20,
  letterSpacing: 20 * -0.015,
  color: ColorName.colorSubtitle.withValues(alpha: 0.6),
);

const _goalValue = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 26,
  height: 32 / 26,
  letterSpacing: -0.6,
  color: ColorName.colorTitle,
);

final class _WaterRingPainter extends CustomPainter {
  const _WaterRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = ColorName.colorWaterRulerTick.withValues(alpha: 0.4);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = ColorName.colorWaterAction;
    canvas.drawCircle(center, radius, track);
    if (progress <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
