part of '../fasting_plan_view.dart';

mixin FastingPlanViewMixin on State<FastingPlanView> {
  List<
      ({
        OnboardingFastingPlan plan,
        String titleKey,
        String subtitleKey,
        String badgeKey,
        Color badgeColor,
      })> get planOptions => [
        (
          plan: OnboardingFastingPlan.sixteenEight,
          titleKey: 'onboarding.plan_16_8_title',
          subtitleKey: 'onboarding.plan_16_8_subtitle',
          badgeKey: 'onboarding.plan_badge_popular',
          badgeColor: ColorName.colorPlanBadgePopular,
        ),
        (
          plan: OnboardingFastingPlan.fourteenTen,
          titleKey: 'onboarding.plan_14_10_title',
          subtitleKey: 'onboarding.plan_14_10_subtitle',
          badgeKey: 'onboarding.plan_badge_beginner',
          badgeColor: ColorName.colorPlanBadgeBeginner,
        ),
        (
          plan: OnboardingFastingPlan.eighteenSix,
          titleKey: 'onboarding.plan_18_6_title',
          subtitleKey: 'onboarding.plan_18_6_subtitle',
          badgeKey: 'onboarding.plan_badge_steady',
          badgeColor: ColorName.colorPlanBadgeSteady,
        ),
        (
          plan: OnboardingFastingPlan.twentyFour,
          titleKey: 'onboarding.plan_20_4_title',
          subtitleKey: 'onboarding.plan_20_4_subtitle',
          badgeKey: 'onboarding.plan_badge_advanced',
          badgeColor: ColorName.colorPlanBadgeAdvanced,
        ),
        (
          plan: OnboardingFastingPlan.omad,
          titleKey: 'onboarding.plan_omad_title',
          subtitleKey: 'onboarding.plan_omad_subtitle',
          badgeKey: 'onboarding.plan_badge_pro',
          badgeColor: ColorName.colorPlanBadgePro,
        ),
        (
          plan: OnboardingFastingPlan.fiveTwo,
          titleKey: 'onboarding.plan_5_2_title',
          subtitleKey: 'onboarding.plan_5_2_subtitle',
          badgeKey: 'onboarding.plan_badge_flexible',
          badgeColor: ColorName.colorPlanBadgeFlexible,
        ),
      ];

  void onBack() {
    context.pop();
  }

  void onPlanSelected(OnboardingFastingPlan plan) {
    context.read<FastingPlanBloc>().add(FastingPlanSelected(plan));
  }

  void onContinue() {
    final plan = context.read<FastingPlanBloc>().state.selected;
    if (plan == null) return;
    context.push(RoutePaths.planHighlight.path, extra: plan);
  }
}
