import 'dart:math' as math;

import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Altı açık 240° yay gauge — Metabolic / Kalori makro halkaları.
final class ArcProgressGauge extends StatelessWidget {
  const ArcProgressGauge({
    required this.progress,
    required this.color,
    required this.valueText,
    required this.label,
    this.size = 108,
    this.valueStyle,
    this.labelStyle,
    super.key,
  });

  final double progress;
  final Color color;
  final String valueText;
  final String label;
  final double size;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final target = progress.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolved = math.min(size, constraints.maxWidth);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: target),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return SizedBox(
              width: resolved,
              height: resolved,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(resolved, resolved),
                    painter: ArcProgressPainter(
                      progress: value,
                      progressColor: color,
                      trackColor: ColorName.colorUnitToggleBg,
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, -0.12),
                    child: Text(
                      valueText,
                      style:
                          valueStyle ?? AppTextStyles.homeMetabolicGaugeValue,
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, 0.92),
                    child: Text(
                      label,
                      style:
                          labelStyle ?? AppTextStyles.homeMetabolicGaugeLabel,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Altı açık yay painter. Varsayılan 240°; uyku ekranı yarım daire kullanır.
final class ArcProgressPainter extends CustomPainter {
  const ArcProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    this.startAngle = _defaultStart,
    this.sweepAngle = _defaultSweep,
    this.strokeWidth = _defaultStroke,
  });

  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double startAngle;
  final double sweepAngle;
  final double strokeWidth;

  static const _defaultStroke = 12.0;
  static const _defaultStart = 150 * math.pi / 180;
  static const _defaultSweep = 240 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackShadow = Paint()
      ..color = const Color(0x1F000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
      ..isAntiAlias = true;
    canvas.drawArc(
      rect.shift(const Offset(0, 1.2)),
      startAngle,
      sweepAngle,
      false,
      trackShadow,
    );

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);

    final highlight = Paint()
      ..color = ColorName.colorWhite.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final highlightRect = Rect.fromCircle(
      center: Offset(center.dx, center.dy - 0.8),
      radius: radius - strokeWidth / 2 + 0.5,
    );
    canvas.drawArc(highlightRect, startAngle, sweepAngle, false, highlight);

    if (progress <= 0.001) return;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ArcProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.startAngle != startAngle ||
        oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
