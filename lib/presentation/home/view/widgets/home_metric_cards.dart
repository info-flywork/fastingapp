part of '../home_view.dart';

/// Su ve adım metrik kartları (yan yana).
final class HomeMetricCards extends StatelessWidget {
  const HomeMetricCards({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon.image(width: 28, height: 28, fit: BoxFit.contain),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  labelKey.tr(),
                  style: AppTextStyles.homeMetricLabel,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: ColorName.colorSubtitle.withValues(alpha: 0.4),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: valueKey.tr(args: ['$value']),
                  style: AppTextStyles.homeMetricValue,
                ),
                TextSpan(
                  text: goalKey.tr(args: ['$goal']),
                  style: AppTextStyles.homeMetricGoal,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: trackColor,
              color: fillColor,
            ),
          ),
        ],
      ),
    );
  }
}
