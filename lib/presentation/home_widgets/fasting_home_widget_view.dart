import 'dart:math' as math;

import 'package:fastingapp/generated/app_images.g.dart';
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
    this.live = false,
    super.key,
  });

  final String timeLabel;
  final String leftLabel;
  final String statusLabel;
  final double progress;

  /// Canlı geri sayım: süre metni ve ilerleme yayı görselde boş bırakılır,
  /// widget'ın yerel kodu ([liveSpec] konumunda) çizer.
  final bool live;

  static const logicalSize = Size(310, 310);

  /// Yerel katman için konumlar (mantıksal piksel; görsel 310×310).
  /// Halka: üst boşluk 56, altta durum satırı (28) ve 18 boşluk → 208'lik
  /// alanın ortası; süre metni halkanın içindeki sütunun ilk satırı.
  static Map<String, Object> liveSpec() => {
    'w': 310,
    'h': 310,
    'tx': 155,
    'ty': 149,
    'ta': 'c',
    'ts': 48,
    'tc': _hex(ColorName.colorTitle),
    'rx': 155,
    'ry': 160,
    'rr': 89,
    'rs': 22,
    'rc': _hex(ColorName.colorCtaGradientBottom),
  };

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
                            painter: _FastingRingPainter(
                              progress: live ? 0 : progress,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  timeLabel,
                                  style: live
                                      ? _time.copyWith(
                                          color: Colors.transparent,
                                        )
                                      : _time,
                                ),
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
                child: AppImages.widget1.image(width: 220, fit: BoxFit.contain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _Logo extends StatelessWidget {
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

final class _FastingRingPainter extends CustomPainter {
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

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
