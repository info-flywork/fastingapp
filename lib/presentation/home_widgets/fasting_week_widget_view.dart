import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';

/// This Week home widget — haftalık çubuklar, chip, mascot.
final class FastingWeekWidgetView extends StatelessWidget {
  const FastingWeekWidgetView({
    required this.title,
    required this.completedLabel,
    required this.weekdayLabels,
    required this.dayProgress,
    required this.cheerLabel,
    super.key,
  });

  final String title;
  final String completedLabel;
  final List<String> weekdayLabels;
  final List<double> dayProgress;
  final String cheerLabel;

  /// Figma — 658 × 310, padding 24, gap 12.
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
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: _title),
                        const Spacer(),
                        Text(completedLabel, style: _count),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _WeekChart(
                      weekdayLabels: weekdayLabels,
                      dayProgress: dayProgress,
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(left: 56),
                      child: _CheerChip(label: cheerLabel),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 8,
                bottom: -18,
                child: AppImages.widget1.image(
                  height: 150,
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

final class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.weekdayLabels, required this.dayProgress});

  final List<String> weekdayLabels;
  final List<double> dayProgress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 88,
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Align(
                    child: _DayBar(
                      progress: i < dayProgress.length ? dayProgress[i] : 0,
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
                  style: _day,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

final class _DayBar extends StatelessWidget {
  const _DayBar({required this.progress});

  final double progress;

  static const _trackH = 88.0;
  static const _barW = 29.0;

  @override
  Widget build(BuildContext context) {
    // Negatif: haftalık planda serbest gün (hedef yok) — soluk sütun.
    final restDay = progress < 0;
    final fillH = (_trackH * progress.clamp(0.0, 1.0)).roundToDouble();
    return SizedBox(
      width: _barW,
      height: _trackH,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColorName.colorCtaGradientBottom.withValues(
            alpha: restDay ? 0.03 : 0.1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: fillH <= 0
              ? const SizedBox.shrink()
              : Container(
                  width: _barW,
                  height: fillH,
                  decoration: const BoxDecoration(
                    color: Color(0xFF93D29C),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
        ),
      ),
    );
  }
}

final class _CheerChip extends StatelessWidget {
  const _CheerChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 297),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColorName.colorMealPositive.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppImages.tree.image(height: 44, fit: BoxFit.contain),
              const SizedBox(width: 10),
              Flexible(child: Text(label, style: _cheer)),
            ],
          ),
        ),
      ),
    );
  }
}

const _title = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 28,
  height: 32 / 28,
  letterSpacing: -0.5,
  color: ColorName.colorTitle,
);

const _count = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 28,
  height: 32 / 28,
  letterSpacing: -0.5,
  color: ColorName.colorMealPositive,
);

const _day = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 16,
  height: 20 / 16,
  color: ColorName.colorTitle,
);

const _cheer = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 18,
  height: 1,
  color: ColorName.colorSubtitle,
);
