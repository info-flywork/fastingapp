import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/goal/bloc/goal_bloc.dart';

/// Onboarding + Edit Profile ortak hedef seçenekleri.
abstract final class GoalOptionsCatalog {
  static List<
      ({
        OnboardingGoal goal,
        String titleKey,
        String subtitleKey,
        String iconPath,
        String? badgeKey,
      })> get items => [
        (
          goal: OnboardingGoal.loseWeight,
          titleKey: 'onboarding.goal_lose_weight_title',
          subtitleKey: 'onboarding.goal_lose_weight_subtitle',
          iconPath: Assets.images.weigher.path,
          badgeKey: 'onboarding.most_popular',
        ),
        (
          goal: OnboardingGoal.buildHabit,
          titleKey: 'onboarding.goal_build_habit_title',
          subtitleKey: 'onboarding.goal_build_habit_subtitle',
          iconPath: Assets.images.plant.path,
          badgeKey: null,
        ),
        (
          goal: OnboardingGoal.moreEnergy,
          titleKey: 'onboarding.goal_more_energy_title',
          subtitleKey: 'onboarding.goal_more_energy_subtitle',
          iconPath: Assets.images.greenApple.path,
          badgeKey: null,
        ),
        (
          goal: OnboardingGoal.gutReset,
          titleKey: 'onboarding.goal_gut_reset_title',
          subtitleKey: 'onboarding.goal_gut_reset_subtitle',
          iconPath: Assets.images.bowel.path,
          badgeKey: null,
        ),
      ];

  static String titleKeyFor(OnboardingGoal goal) {
    return items.firstWhere((e) => e.goal == goal).titleKey;
  }
}
