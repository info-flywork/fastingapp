part of '../home_view.dart';

/// Home kilo kayıtları kartı — su/adım kartlarının 12px altında.
final class HomeWeightCard extends StatelessWidget {
  const HomeWeightCard({this.onTap, this.onEditTap, super.key});

  final VoidCallback? onTap;
  final VoidCallback? onEditTap;

  static const currentKg = 102.5;
  static const _startKg = 112.2;
  static const _targetKg = 75.2;

  @override
  Widget build(BuildContext context) {
    final progress = ((_startKg - currentKg) / (_startKg - _targetKg)).clamp(
      0.0,
      1.0,
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
                AppImages.weigher2.image(
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
                Text(
                  _formatKg(currentKg),
                  style: AppTextStyles.homeWeightValue,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    'home.weight_unit'.tr(),
                    style: AppTextStyles.homeWeightUnit,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onEditTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Assets.icons.solarPen2LineDuotone2.svg(
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            WeightProgressBar(progress: progress),
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
