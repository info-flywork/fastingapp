part of '../home_view.dart';

/// Su ve adım metrik kartları (yan yana).
final class HomeMetricCards extends StatelessWidget {
  const HomeMetricCards({required this.onWaterTapped, super.key});

  final VoidCallback onWaterTapped;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Row(
        children: [
          Expanded(
            child: _MetricCard(
              icon: Assets.images.water,
              labelKey: 'home.water',
              value: 100,
              goal: 2500,
              valueKey: 'home.water_value',
              goalKey: 'home.water_goal',
              trackColor: ColorName.colorWaterTrack,
              fillColor: ColorName.colorWaterFill,
              progress: 100 / 2500,
              wavyFill: true,
              onTap: onWaterTapped,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricCard(
              icon: Assets.images.steps,
              labelKey: 'home.steps',
              value: 1000,
              goal: 8000,
              valueKey: 'home.steps_value',
              goalKey: 'home.steps_goal',
              trackColor: ColorName.colorStepsTrack,
              fillColor: ColorName.colorStepsFill,
              progress: 1000 / 8000,
            ),
          ),
        ],
      ),
    );
  }
}

final class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.labelKey,
    required this.value,
    required this.goal,
    required this.valueKey,
    required this.goalKey,
    required this.trackColor,
    required this.fillColor,
    required this.progress,
    this.wavyFill = false,
    this.onTap,
  });

  final AssetGenImage icon;
  final String labelKey;
  final int value;
  final int goal;
  final String valueKey;
  final String goalKey;
  final Color trackColor;
  final Color fillColor;
  final double progress;
  final bool wavyFill;
  final VoidCallback? onTap;

  static const _iconSize = 40.0;
  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorWhite,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  icon.image(
                    width: _iconSize,
                    height: _iconSize,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      labelKey.tr(),
                      style: AppTextStyles.homeMetricLabel,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: ColorName.colorTitle,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: valueKey.tr(args: ['$value']),
                      style: AppTextStyles.homeMetricValue.copyWith(
                        color: const Color(0xFF1C1C21),
                      ),
                    ),
                    TextSpan(
                      text: goalKey.tr(args: ['$goal']),
                      style: AppTextStyles.homeMetricGoal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _MetricProgressBar(
                progress: progress,
                trackColor: trackColor,
                fillColor: fillColor,
                wavy: wavyFill,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figma Frame — 35px capsule track.
final class _MetricProgressBar extends StatelessWidget {
  const _MetricProgressBar({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.wavy,
  });

  final double progress;
  final Color trackColor;
  final Color fillColor;
  final bool wavy;

  static const height = 35.0;

  /// Figma’dan çıkarılmış dalga ucu (yakın plan) — lojik genişlik.
  static const _waveLogicalW = 18.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final p = progress.clamp(0.0, 1.0);
        final target = width * p;

        return SizedBox(
          height: height,
          width: width,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: wavy
                  ? _WaterWaveFill(
                      target: target,
                      fillColor: fillColor,
                      waveLogicalW: _waveLogicalW,
                    )
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: target,
                        height: height,
                        child: ColoredBox(color: fillColor),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

/// Su dolgusu — Figma `water_progress_wave.png` ucu + gerekirse düz gövde.
final class _WaterWaveFill extends StatelessWidget {
  const _WaterWaveFill({
    required this.target,
    required this.fillColor,
    required this.waveLogicalW,
  });

  final double target;
  final Color fillColor;
  final double waveLogicalW;

  @override
  Widget build(BuildContext context) {
    if (target <= 0) return const SizedBox.shrink();

    // Düşük progress: sadece dalga ucu (Figma 100ml).
    // Yüksek progress: mavi gövde + uçta dalga.
    final bodyW = math.max(0.0, target - waveLogicalW * 0.65);
    final waveLeft = bodyW;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        if (bodyW > 0)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: bodyW + 4,
            child: ColoredBox(color: fillColor),
          ),
        Positioned(
          left: waveLeft,
          top: 0,
          bottom: 0,
          child: Image.asset(
            'assets/images/water_progress_wave.png',
            height: _MetricProgressBar.height,
            fit: BoxFit.fitHeight,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
        ),
      ],
    );
  }
}
