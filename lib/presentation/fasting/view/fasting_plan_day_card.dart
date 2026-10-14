import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/domain/fasting/weekly_schedule.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Haftalık planda oruç günü olmayan bugün: serbest gün bilgisi ya da
/// 500 kcal günü + "Tamamladım / Atladım" işareti.
final class FastingPlanDayCard extends StatelessWidget {
  const FastingPlanDayCard({
    required this.day,
    required this.checkin,
    required this.onCheckin,
    super.key,
  });

  final WeeklyDay day;

  /// `done` | `skipped` | null.
  final String? checkin;
  final ValueChanged<bool> onCheckin;

  @override
  Widget build(BuildContext context) {
    final reduced = day.type == WeeklyDayType.reduced;
    final kcal = '${day.kcal ?? WeeklyRules.reducedKcal}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: reduced
              ? ColorName.colorPlanChipBreakfastBg
              : ColorName.colorWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reduced
                    ? 'fasting_page.reduced_day_title'.tr(args: [kcal])
                    : 'fasting_page.free_day_title'.tr(),
                style: AppTextStyles.planOptionTitle,
              ),
              const SizedBox(height: 4),
              Text(
                reduced
                    ? 'fasting_page.reduced_day_body'.tr(args: [kcal])
                    : 'fasting_page.free_day_body'.tr(),
                style: AppTextStyles.optionSubtitle,
              ),
              if (reduced) ...[
                const SizedBox(height: 12),
                if (checkin != null)
                  Text(
                    checkin == 'done'
                        ? 'fasting_page.reduced_day_done'.tr()
                        : 'fasting_page.reduced_day_skipped'.tr(),
                    style: AppTextStyles.plansChipLabel.copyWith(
                      color: ColorName.colorPlanChipBreakfastText,
                    ),
                  ),
                if (checkin != null) const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'fasting_page.reduced_day_done_cta'.tr(),
                        showIcon: false,
                        isEnabled: checkin != 'done',
                        decoration: AppButtonDecoration.primary(),
                        onPressed: () => onCheckin(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'fasting_page.reduced_day_skip_cta'.tr(),
                        showIcon: false,
                        isEnabled: checkin != 'skipped',
                        decoration: AppButtonDecoration.homeJoin(),
                        onPressed: () => onCheckin(false),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
