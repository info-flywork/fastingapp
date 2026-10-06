import 'dart:math' as math;

import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Orta su widget'ı — halka, son kayıtlar ve ekleme yazısı.
final class WaterMediumWidgetView extends StatelessWidget {
  const WaterMediumWidgetView({
    required this.currentMl,
    required this.goalMl,
    required this.goalLabel,
    required this.unitLabel,
    required this.timelineLabel,
    required this.addLabel,
    required this.sips,
    super.key,
  });

  final int currentMl;
  final int goalMl;
  final String goalLabel;
  final String unitLabel;
  final String timelineLabel;
  final String addLabel;
  final List<({int ml, String timeLabel})> sips;

  static const logicalSize = Size(658, 310);

  @override
  Widget build(BuildContext context) {
    final progress = goalMl <= 0 ? 0.0 : (currentMl / goalMl).clamp(0.0, 1.0);
    return SizedBox(
      width: logicalSize.width,
      height: logicalSize.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColorName.colorWhite,
          borderRadius: BorderRadius.circular(60),
          border: Border.all(color: ColorName.colorWaterRulerTick),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
          child: Row(
            children: [
              _GoalColumn(
                currentMl: currentMl,
                goalMl: goalMl,
                goalLabel: goalLabel,
                unitLabel: unitLabel,
                progress: progress,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _TimelineColumn(
                  timelineLabel: timelineLabel,
                  addLabel: addLabel,
                  unitLabel: unitLabel,
                  sips: sips,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _GoalColumn extends StatelessWidget {
  const _GoalColumn({
    required this.currentMl,
    required this.goalMl,
    required this.goalLabel,
    required this.unitLabel,
    required this.progress,
  });

  final int currentMl;
  final int goalMl;
  final String goalLabel;
  final String unitLabel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 176,
            height: 176,
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
          const SizedBox(height: 10),
          Text(goalLabel, style: _goalLabel),
          const SizedBox(height: 2),
          Text('$goalMl $unitLabel', style: _goalValue),
        ],
      ),
    );
  }
}

final class _TimelineColumn extends StatelessWidget {
  const _TimelineColumn({
    required this.timelineLabel,
    required this.addLabel,
    required this.unitLabel,
    required this.sips,
  });

  final String timelineLabel;
  final String addLabel;
  final String unitLabel;
  final List<({int ml, String timeLabel})> sips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(timelineLabel, style: _timeline),
        const SizedBox(height: 12),
        if (sips.isNotEmpty) ...[
          Row(
            children: [
              for (var i = 0; i < sips.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _SipCard(
                    ml: sips[i].ml,
                    timeLabel: sips[i].timeLabel,
                    unitLabel: unitLabel,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: ColorName.colorWaterAction,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Center(child: Text(addLabel, style: _addLabel)),
          ),
        ),
      ],
    );
  }
}

final class _SipCard extends StatelessWidget {
  const _SipCard({
    required this.ml,
    required this.timeLabel,
    required this.unitLabel,
  });

  final int ml;
  final String timeLabel;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWaterWaveLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: Column(
          children: [
            Image.asset(Assets.images.droplet.path, width: 32, height: 32),
            const SizedBox(height: 6),
            Text('$ml$unitLabel', style: _sipAmount),
            const SizedBox(height: 4),
            Text(timeLabel, style: _sipTime),
          ],
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

final _timeline = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w700,
  fontSize: 20,
  height: 1,
  letterSpacing: 1.8,
  color: ColorName.colorSubtitle.withValues(alpha: 0.6),
);

const _sipAmount = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 16,
  height: 1,
  color: ColorName.colorTitle,
);

final _sipTime = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w400,
  fontSize: 16,
  height: 1,
  color: ColorName.colorSubtitle.withValues(alpha: 0.6),
);

const _addLabel = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 22,
  height: 1,
  color: ColorName.colorWhite,
);

final class _WaterRingPainter extends CustomPainter {
  const _WaterRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
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
