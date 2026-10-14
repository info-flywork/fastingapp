part of '../home_view.dart';

/// Home kilo kayıtları kartı — su/adım kartlarının 12px altında.
final class HomeWeightCard extends StatelessWidget {
  const HomeWeightCard({
    this.currentKg,
    this.startKg,
    this.goalKg,
    this.unit = 'kg',
    this.onTap,
    this.onEditTap,
    super.key,
  });

  /// Sunucu özetinden (`summary.weight`); kayıt yoksa null.
  final double? currentKg;
  final double? startKg;
  final double? goalKg;

  /// `kg` | `lb` (önceden lb seçilse de kg gösteriliyordu).
  final String unit;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;

  /// Düzenleme diyaloğu için kilo bilinmiyorsa başlangıç değeri.
  static const fallbackKg = 70.0;

  @override
  Widget build(BuildContext context) {
    // Kayıt yoksa sahte değer yerine "–" (önceden 70 kg gösteriliyordu).
    final current = currentKg ?? startKg;
    final start = startKg ?? current;
    final target = goalKg;
    final progress = weightProgressOf(
      start: start,
      goal: target,
      current: current,
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
                  current == null ? '–' : WeightUnits.amount(current, unit),
                  style: AppTextStyles.homeWeightValue,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    WeightUnits.label(unit),
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
            Row(
              children: [
                Expanded(
                  child: _WeightBoundLabel(
                    labelKey: 'home.weight_start',
                    kg: start,
                    unit: unit,
                  ),
                ),
                _WeightBoundLabel(
                  labelKey: 'home.weight_target',
                  kg: target,
                  unit: unit,
                  alignEnd: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _WeightBoundLabel extends StatelessWidget {
  const _WeightBoundLabel({
    required this.labelKey,
    required this.kg,
    required this.unit,
    this.alignEnd = false,
  });

  final String labelKey;
  final double? kg;
  final String unit;
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
            text: kg == null
                ? '–'
                : '${WeightUnits.amount(kg!, unit)}${WeightUnits.label(unit)}',
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
