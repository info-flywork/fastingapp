part of '../home_view.dart';

/// Home kilo kayıtları kartı — su/adım kartlarının 12px altında.
final class HomeWeightCard extends StatelessWidget {
  const HomeWeightCard({super.key});

  static const _currentKg = 102.5;
  static const _startKg = 112.2;
  static const _targetKg = 75.2;

  @override
  Widget build(BuildContext context) {
    final progress = ((_startKg - _currentKg) / (_startKg - _targetKg)).clamp(
      0.0,
      1.0,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Assets.images.weigher2.image(
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'home.weight_records'.tr(),
                  style: AppTextStyles.homeWeightTitle,
                ),
              ),
              Assets.icons.solarAltArrowUpLineDuotoneRight.svg(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatKg(_currentKg), style: AppTextStyles.homeWeightValue),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  'home.weight_unit'.tr(),
                  style: AppTextStyles.homeWeightUnit,
                ),
              ),
              const Spacer(),
              Assets.icons.solarPen2LineDuotone2.svg(
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  ColorName.colorTitle,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _WeightProgressBar(progress: progress),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _WeightBoundLabel(
                  labelKey: 'home.weight_start',
                  kg: _startKg,
                ),
              ),
              _WeightBoundLabel(
                labelKey: 'home.weight_target',
                kg: _targetKg,
                alignEnd: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatKg(double kg) {
    if (kg == kg.roundToDouble()) return '${kg.toInt()}';
    return kg.toStringAsFixed(1);
  }
}

final class _WeightBoundLabel extends StatelessWidget {
  const _WeightBoundLabel({
    required this.labelKey,
    required this.kg,
    this.alignEnd = false,
  });

  final String labelKey;
  final double kg;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${labelKey.tr()} ',
            style: AppTextStyles.homeWeightBoundLabel,
          ),
          TextSpan(
            text: '${HomeWeightCard._formatKg(kg)}${'home.weight_unit'.tr()}',
            style: AppTextStyles.homeWeightBoundValue,
          ),
        ],
      ),
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

final class _WeightProgressBar extends StatelessWidget {
  const _WeightProgressBar({required this.progress});

  final double progress;

  static const _height = 20.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, _) {
        return SizedBox(
          height: _height,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ColorName.colorStepsTrack,
              borderRadius: BorderRadius.circular(99999),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99999),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: animatedProgress,
                  heightFactor: 1,
                  child: const ColoredBox(color: ColorName.colorStepsFill),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
