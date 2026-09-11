import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Weight projection ekranındaki eğri grafik.
final class WeightProjectionChart extends StatelessWidget {
  const WeightProjectionChart({
    required this.progress,
    super.key,
  });

  /// 0–1 çizim ilerlemesi.
  final double progress;

  static const _height = 168.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WeightProjectionChartPainter(
          progress: progress.clamp(0.0, 1.0),
        ),
      ),
    );
  }
}

final class _WeightProjectionChartPainter extends CustomPainter {
  _WeightProjectionChartPainter({required this.progress});

  final double progress;

  static const _startRadius = 7.5;
  static const _endRadius = 13.0;
  static const _endBorder = 4.0;
  static const _lineWidth = 5.0;
  static const _dashWidth = 9.0;
  static const _dashGap = 9.0;
  static const _dashStroke = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    const left = _endRadius;
    final right = size.width - _endRadius;
    const top = _startRadius + 4;
    final bottom = size.height - _dashStroke / 2 - 4;
    const start = Offset(left, top);
    final end = Offset(right, bottom - 18);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        left + (right - left) * 0.35,
        top + (bottom - top) * 0.08,
        left + (right - left) * 0.65,
        top + (bottom - top) * 0.55,
        end.dx,
        end.dy,
      );

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final drawLength = metric.length * progress;
    final drawn = metric.extractPath(0, drawLength);
    final tip = metric.getTangentForOffset(drawLength)?.position ?? start;

    _paintFill(canvas, drawn, tip, start, bottom, size.width);
    _paintDash(canvas, left, right, bottom);
    _paintLine(canvas, drawn);

    if (progress > 0.02) {
      canvas.drawCircle(
        start,
        _startRadius,
        Paint()..color = ColorName.colorWhite,
      );
    }

    if (progress > 0.98) {
      canvas
        ..drawCircle(
          end,
          _endRadius,
          Paint()..color = ColorName.colorWhite,
        )
        ..drawCircle(
          end,
          _endRadius - _endBorder,
          Paint()..color = ColorName.colorWeightProjectionGoalDot,
        );
    } else if (progress > 0.05) {
      canvas.drawCircle(
        tip,
        6,
        Paint()..color = ColorName.colorWhite,
      );
    }
  }

  void _paintFill(
    Canvas canvas,
    Path drawn,
    Offset tip,
    Offset start,
    double baselineY,
    double width,
  ) {
    if (progress <= 0) return;

    final fill = Path()
      ..addPath(drawn, Offset.zero)
      ..lineTo(tip.dx, baselineY)
      ..lineTo(start.dx, baselineY)
      ..close();

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(width / 2, start.dy),
        Offset(width / 2, baselineY),
        [
          ColorName.colorWhite.withValues(alpha: 0.33),
          ColorName.colorWhite.withValues(alpha: 0),
        ],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawPath(fill, paint);
  }

  void _paintDash(Canvas canvas, double left, double right, double y) {
    final paint = Paint()
      ..color = ColorName.colorWhite.withValues(alpha: 0.15)
      ..strokeWidth = _dashStroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    var x = left;
    while (x < right) {
      final endX = math.min(x + _dashWidth, right);
      canvas.drawLine(Offset(x, y), Offset(endX, y), paint);
      x += _dashWidth + _dashGap;
    }
  }

  void _paintLine(Canvas canvas, Path drawn) {
    final paint = Paint()
      ..color = ColorName.colorWhite
      ..strokeWidth = _lineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(drawn, paint);
  }

  @override
  bool shouldRepaint(covariant _WeightProjectionChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
