import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_highlight_view.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_info_chip.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/bloc/fasting_plan_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Fasting plan sonrası "chef's kiss" highlight.
final class PlanHighlightView extends StatelessWidget {
  const PlanHighlightView({
    required this.plan,
    super.key,
  });

  final OnboardingFastingPlan plan;

  String get _planTitleKey => switch (plan) {
        OnboardingFastingPlan.sixteenEight => 'onboarding.plan_16_8_title',
        OnboardingFastingPlan.fourteenTen => 'onboarding.plan_14_10_title',
        OnboardingFastingPlan.eighteenSix => 'onboarding.plan_18_6_title',
        OnboardingFastingPlan.twentyFour => 'onboarding.plan_20_4_title',
        OnboardingFastingPlan.omad => 'onboarding.plan_omad_title',
        OnboardingFastingPlan.fiveTwo => 'onboarding.plan_5_2_title',
      };

  static const _timelineKeys = [
    'onboarding.plan_highlight_day_1_2',
    'onboarding.plan_highlight_day_3_4',
    'onboarding.plan_highlight_week_2',
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingHighlightView(
      mediaPath: Assets.gifs.mascotGiggle.path,
      gradientColors: const [
        ColorName.colorNotedGradientTop,
        ColorName.colorNotedGradientBottom,
      ],
      title: 'onboarding.plan_highlight_title'.tr(
        args: [_planTitleKey.tr()],
      ),
      subtitle: Text(
        'onboarding.plan_highlight_subtitle'.tr(),
        textAlign: TextAlign.center,
      ),
      middle: Column(
        children: [
          for (var i = 0; i < _timelineKeys.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            OnboardingInfoChip(
              expand: true,
              textAlign: TextAlign.center,
              label: _timelineKeys[i].tr(),
              labelStyle: AppTextStyles.notedSummaryChip,
            ),
          ],
        ],
      ),
      buttonLabel: 'onboarding.set_my_window'.tr(),
      onContinue: () => context.push(RoutePaths.mealWindow.path),
    );
  }
}
