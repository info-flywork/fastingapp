part of '../home_view.dart';

/// Home öğün kayıtları kartı — metabolic kartının altında.
final class HomeMealRecordsCard extends StatelessWidget {
  const HomeMealRecordsCard({this.lastMeal, this.onTap, super.key});

  final SummaryLastMeal? lastMeal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppImages.orangeBell.image(
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'home.meal_records'.tr(),
                    style: AppTextStyles.homeMealRecordsTitle,
                  ),
                ),
                Assets.icons.solarAltArrowUpLineDuotoneRight.svg(),
              ],
            ),
            const SizedBox(height: 16),
            _MealTimeline(lastMeal: lastMeal),
            const SizedBox(height: 16),
            AppButton(
              label: 'home.save_a_meal'.tr(),
              onPressed: onTap,
              decoration: AppButtonDecoration.homeJoin(),
              showIcon: false,
            ),
          ],
        ),
      ),
    );
  }
}

final class _MealTimeline extends StatelessWidget {
  const _MealTimeline({this.lastMeal});

  final SummaryLastMeal? lastMeal;

  static const _lineColor = Color(0x993C3C43);
  static const _dotSize = 8.0;

  @override
  Widget build(BuildContext context) {
    if (lastMeal == null) return const SizedBox.shrink();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                Container(
                  width: _dotSize * 1.5,
                  height: _dotSize * 1.5,
                  decoration: BoxDecoration(
                    color: _lineColor.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 1.5,
                      color: _lineColor.withValues(alpha: 0.4),
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
                _MealTimestamp(eatenAt: lastMeal!.eatenAt),
                const SizedBox(height: 10),
                _MealEntryCard(title: lastMeal!.title, kcal: lastMeal!.kcal),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _MealTimestamp extends StatelessWidget {
  const _MealTimestamp({required this.eatenAt});

  final DateTime eatenAt;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final label = DateFormat('MMMM d, HH:mm', locale).format(eatenAt);
    return Text(label, style: AppTextStyles.homeMealTimestamp);
  }
}

final class _MealEntryCard extends StatelessWidget {
  const _MealEntryCard({this.title, this.kcal});

  final String? title;
  final int? kcal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorName.colorHomeChipBg, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ColorName.colorStepsTrack,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: AppImages.orangeBell.image(
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: title != null && title!.isNotEmpty
                ? Text(title!, style: AppTextStyles.homeMealRecordsTitle)
                : Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (kcal != null)
                        _MealTag(
                          labelKey: 'home.meal_tag_full',
                          labelOverride: '$kcal kcal',
                        ),
                      const _MealTag(labelKey: 'home.meal_tag_keto'),
                    ],
                  ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: AppImages.mealRecordEmoji.image(
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

final class _MealTag extends StatelessWidget {
  const _MealTag({required this.labelKey, this.labelOverride});

  final String labelKey;
  final String? labelOverride;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: ColorName.colorHomeChipBg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        labelOverride ?? labelKey.tr(),
        style: AppTextStyles.homeMealTag,
      ),
    );
  }
}
