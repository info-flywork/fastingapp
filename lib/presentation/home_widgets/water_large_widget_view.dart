import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Büyük su widget'ı — halka, haftalık çubuklar ve hatırlatma.
final class WaterLargeWidgetView extends StatelessWidget {
  const WaterLargeWidgetView({
    required this.currentMl,
    required this.goalMl,
    required this.unitLabel,
    required this.title,
    required this.subtitle,
    required this.intakeLabel,
    required this.percentLabel,
    required this.weeklyLabel,
    required this.historyLabel,
    required this.reminderLabel,
    required this.addWaterLabel,
    required this.weekdayLabels,
    required this.weekProgress,
    required this.todayIndex,
    this.bell,
    super.key,
  });

  final int currentMl;
  final int goalMl;
  final String unitLabel;
  final String title;
  final String subtitle;
  final String intakeLabel;
  final String percentLabel;
  final String weeklyLabel;
  final String historyLabel;
  final String reminderLabel;
  final String addWaterLabel;
  final List<String> weekdayLabels;
  final List<double> weekProgress;
  final int todayIndex;
  final ui.Picture? bell;

  static const logicalSize = Size(658, 690);

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
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _title),
              const SizedBox(height: 2),
              Text(subtitle, style: _subtitle),
              const SizedBox(height: 22),
              _IntakeCard(
                currentMl: currentMl,
                goalMl: goalMl,
                unitLabel: unitLabel,
                intakeLabel: intakeLabel,
                percentLabel: percentLabel,
                progress: progress,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Text(weeklyLabel, style: _weekly),
                  const Spacer(),
                  Text(historyLabel, style: _history),
                ],
              ),
              const SizedBox(height: 16),
              _WeekChart(
                weekdayLabels: weekdayLabels,
                weekProgress: weekProgress,
                todayIndex: todayIndex,
              ),
              const Spacer(),
              _Footer(
                reminderLabel: reminderLabel,
                addWaterLabel: addWaterLabel,
                bell: bell,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntakeCard extends StatelessWidget {
  const _IntakeCard({
    required this.currentMl,
    required this.goalMl,
    required this.unitLabel,
    required this.intakeLabel,
    required this.percentLabel,
    required this.progress,
  });

  final int currentMl;
  final int goalMl;
  final String unitLabel;
  final String intakeLabel;
  final String percentLabel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWaterWaveLight,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            SizedBox(
              width: 148,
              height: 148,
              child: CustomPaint(
                painter: _WaterRingPainter(progress: progress),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$currentMl', style: _ringAmount),
                    Text(unitLabel, style: _ringUnit),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(intakeLabel, style: _intakeLabel),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$currentMl / $goalMl $unitLabel',
                      style: _intakeValue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: ColorName.colorWhite,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: ColorName.colorWaterAction,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(percentLabel, style: _percent),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({
    required this.weekdayLabels,
    required this.weekProgress,
    required this.todayIndex,
  });

  final List<String> weekdayLabels;
  final List<double> weekProgress;
  final int todayIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _WeekBar(
                      progress: i < weekProgress.length ? weekProgress[i] : 0,
                      isToday: i == todayIndex,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  i < weekdayLabels.length ? weekdayLabels[i] : '',
                  textAlign: TextAlign.center,
                  style: i == todayIndex ? _dayToday : _day,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _WeekBar extends StatelessWidget {
  const _WeekBar({required this.progress, required this.isToday});

  final double progress;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final height = 24 + (progress.clamp(0.0, 1.0) * 136);
    return Container(
      width: 30,
      height: height,
      decoration: BoxDecoration(
        color: isToday
            ? ColorName.colorWaterAction
            : ColorName.colorWaterRulerTick,
        borderRadius: BorderRadius.circular(100),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: ColorName.colorWaterAction.withValues(alpha: 0.25),
                  offset: const Offset(0, 8),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.reminderLabel,
    required this.addWaterLabel,
    required this.bell,
  });

  final String reminderLabel;
  final String addWaterLabel;
  final ui.Picture? bell;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            color: ColorName.colorWaterWaveLight,
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Center(
              child: CustomPaint(
                size: const Size(26, 26),
                painter: _BellPainter(bell),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            reminderLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _reminder,
          ),
        ),
        const SizedBox(width: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: ColorName.colorWaterAction,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Text(addWaterLabel, style: _addWater),
          ),
        ),
      ],
    );
  }
}

class _BellPainter extends CustomPainter {
  const _BellPainter(this.picture);

  final ui.Picture? picture;

  @override
  void paint(Canvas canvas, Size size) {
    final picture = this.picture;
    if (picture == null) return;
    canvas
      ..save()
      ..scale(size.width / 20, size.height / 20)
      ..drawPicture(picture)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _BellPainter oldDelegate) =>
      oldDelegate.picture != picture;
}

class _WaterRingPainter extends CustomPainter {
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

const _title = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 34,
  height: 42 / 34,
  letterSpacing: -0.7,
  color: ColorName.colorTitle,
);

final _subtitle = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 22,
  height: 28 / 22,
  letterSpacing: 22 * -0.015,
  color: ColorName.colorSubtitle.withValues(alpha: 0.6),
);

const _ringAmount = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 48,
  height: 56 / 48,
  letterSpacing: -0.6,
  color: ColorName.colorTitle,
);

final _ringUnit = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 20,
  height: 24 / 20,
  color: ColorName.colorSubtitle.withValues(alpha: 0.6),
);

final _intakeLabel = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 20,
  height: 26 / 20,
  letterSpacing: 20 * -0.015,
  color: ColorName.colorSubtitle.withValues(alpha: 0.6),
);

const _intakeValue = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 44,
  height: 52 / 44,
  letterSpacing: -0.6,
  color: ColorName.colorTitle,
);

const _percent = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 20,
  height: 1,
  color: ColorName.colorWaterAction,
);

const _weekly = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w700,
  fontSize: 28,
  height: 1,
  color: ColorName.colorTitle,
);

const _history = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 20,
  height: 1,
  color: ColorName.colorWaterAction,
);

final _day = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 20,
  height: 1,
  color: ColorName.colorSubtitle.withValues(alpha: 0.6),
);

const _dayToday = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w700,
  fontSize: 20,
  height: 1,
  color: ColorName.colorTitle,
);

const _reminder = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 22,
  height: 1.15,
  color: ColorName.colorTitle,
);

const _addWater = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 22,
  height: 1,
  color: ColorName.colorWhite,
);
