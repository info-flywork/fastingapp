import 'dart:math' as math;

import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Küçük oruç widget'ı — kalan süre ve mascot.
final class FastingHomeWidgetView extends StatelessWidget {
  const FastingHomeWidgetView({
    required this.timeLabel,
    required this.leftLabel,
    required this.statusLabel,
    required this.progress,
    super.key,
  });

  final String timeLabel;
  final String leftLabel;
  final String statusLabel;
  final double progress;

  static const logicalSize = Size(310, 310);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 310,
      height: 310,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(40)),
        child: ColoredBox(
          color: ColorName.colorWhite,
          child: Stack(
            children: [
              const Positioned(top: 20, left: 26, child: _Logo()),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 56, 26, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: CustomPaint(
                            painter: _FastingRingPainter(progress: progress),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(timeLabel, style: _time),
                                Text(leftLabel, style: _left),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(statusLabel, style: _status),
                  ],
                ),
              ),
              Positioned(
                right: -8,
                bottom: -72,
                child: Assets.images.widget1.image(
                  width: 220,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        style: _logo,
        children: [
          TextSpan(
            text: 'Mochi',
            style: TextStyle(color: ColorName.colorTitle),
          ),
          TextSpan(
            text: 'Fast',
            style: TextStyle(color: ColorName.colorCtaGradientBottom),
          ),
        ],
      ),
    );
  }
}

class _FastingRingPainter extends CustomPainter {
  const _FastingRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 22.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = ColorName.colorWaterRulerTick;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = ColorName.colorCtaGradientBottom;
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
  bool shouldRepaint(covariant _FastingRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

const _logo = TextStyle(
  fontFamily: FontFamily.baloo,
  fontSize: 28,
  height: 24 / 28,
  letterSpacing: 28 * -0.015,
);

const _time = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 48,
  height: 56 / 48,
  letterSpacing: -0.5,
  color: ColorName.colorTitle,
);

final _left = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 22,
  height: 1,
  color: ColorName.colorSubtitle.withValues(alpha: 0.6),
);

const _status = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w700,
  fontSize: 20,
  height: 28 / 20,
  letterSpacing: -0.5,
  color: ColorName.colorTitle,
);
