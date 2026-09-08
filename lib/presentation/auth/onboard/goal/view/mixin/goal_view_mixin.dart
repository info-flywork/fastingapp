part of '../goal_view.dart';

mixin GoalViewMixin on State<GoalView> {
  List<
      ({
        OnboardingGoal goal,
        String titleKey,
        String subtitleKey,
        String iconPath,
        String? badgeKey,
      })> get goalOptions => [
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

  void onBack() {
    context.go(RoutePaths.entry.path);
  }

  Future<void> onGoalSelected(OnboardingGoal goal) async {
    context.read<GoalBloc>().add(GoalSelected(goal));
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    await context.push(RoutePaths.goalHighlight.path);
  }
}
