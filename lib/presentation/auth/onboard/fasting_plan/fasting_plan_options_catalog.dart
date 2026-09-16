import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/bloc/fasting_plan_bloc.dart';
import 'package:flutter/material.dart';

/// Onboarding + Edit Profile ortak oruç planı seçenekleri.
abstract final class FastingPlanOptionsCatalog {
  static List<
      ({
        OnboardingFastingPlan plan,
        String titleKey,
        String subtitleKey,
        String badgeKey,
        Color badgeColor,
      })> get items => [
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

  static String titleKeyFor(OnboardingFastingPlan plan) {
    return items.firstWhere((e) => e.plan == plan).titleKey;
  }
}
