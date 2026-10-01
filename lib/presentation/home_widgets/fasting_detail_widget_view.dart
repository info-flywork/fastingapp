import 'dart:math' as math;

import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Geniş oruç widget'ı — halka, başlangıç, bitiş ve hedef.
final class FastingDetailWidgetView extends StatelessWidget {
  const FastingDetailWidgetView({
    required this.timeLabel,
    required this.leftLabel,
    required this.progress,
    required this.startCaption,
    required this.endCaption,
    required this.goalCaption,
    required this.startValue,
    required this.endValue,
    required this.goalValue,
    required this.praise,
    super.key,
  });

  final String timeLabel;
  final String leftLabel;
  final double progress;
  final String startCaption;
  final String endCaption;
  final String goalCaption;
  final String startValue;
  final String endValue;
  final String goalValue;
  final String praise;

  static const logicalSize = Size(658, 310);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: logicalSize.width,
      height: logicalSize.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColorName.colorWhite,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: ColorName.colorWaterRulerTick),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(39)),
          child: Stack(
            children: [
              const Positioned(top: 20, right: 26, child: _Logo()),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 48, 26, 12),
                child: _Body(
                  timeLabel: timeLabel,
                  leftLabel: leftLabel,
                  progress: progress,
                  startCaption: startCaption,
                  endCaption: endCaption,
                  goalCaption: goalCaption,
                  startValue: startValue,
                  endValue: endValue,
                  goalValue: goalValue,
                  praise: praise,
                ),
              ),
              Positioned(
                right: -4,
                bottom: -6,
                child: Assets.images.widget1.image(
                  height: 168,
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

class _Body extends StatelessWidget {
  const _Body({
    required this.timeLabel,
    required this.leftLabel,
    required this.progress,
    required this.startCaption,
    required this.endCaption,
    required this.goalCaption,
    required this.startValue,
    required this.endValue,
    required this.goalValue,
    required this.praise,
  });

  final String timeLabel;
  final String leftLabel;
  final double progress;
  final String startCaption;
  final String endCaption;
  final String goalCaption;
  final String startValue;
  final String endValue;
  final String goalValue;
  final String praise;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 214,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 188,
                    height: 188,
                    child: CustomPaint(
                      painter: _RingPainter(progress: progress),
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
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Stat(
                      icon: Assets.images.start,
                      caption: startCaption,
                      value: startValue,
                      showDivider: true,
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      icon: Assets.images.end,
                      caption: endCaption,
                      value: endValue,
                      showDivider: true,
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      icon: Assets.images.hours,
                      caption: goalCaption,
                      value: goalValue,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, right: 150),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ColorName.colorMealPositive.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Text(praise, style: _praise),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.caption,
    required this.value,
    this.showDivider = false,
  });

  final AssetGenImage icon;
  final String caption;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                right: BorderSide(
                  color: ColorName.colorSubtitle.withValues(alpha: 0.1),
                ),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            icon.image(height: 36, fit: BoxFit.contain),
            const SizedBox(height: 6),
            Text(caption, style: _caption, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(value, style: _value, textAlign: TextAlign.center),
          ],
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

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

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
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

const _logo = TextStyle(
  fontFamily: FontFamily.baloo,
  fontSize: 24,
  height: 20 / 24,
  letterSpacing: 24 * -0.015,
);

const _time = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 40,
  height: 48 / 40,
  letterSpacing: -0.5,
  color: ColorName.colorTitle,
);

final _left = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 16,
  height: 1,
  color: ColorName.colorSubtitle.withValues(alpha: 0.6),
);

const _caption = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 14,
  height: 1,
  color: ColorName.colorSubtitle,
);

const _value = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w700,
  fontSize: 16,
  height: 1,
  letterSpacing: -0.5,
  color: ColorName.colorTitle,
);

const _praise = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 18,
  height: 1,
  color: ColorName.colorSubtitle,
);
