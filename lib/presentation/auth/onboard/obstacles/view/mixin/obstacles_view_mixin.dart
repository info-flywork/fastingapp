part of '../obstacles_view.dart';

mixin ObstaclesViewMixin on State<ObstaclesView> {
  List<({OnboardingObstacle obstacle, String titleKey, String iconPath})>
      get obstacleOptions => [
            (
              obstacle: OnboardingObstacle.tooRestrictive,
              titleKey: 'onboarding.obstacle_restrictive',
              iconPath: Assets.images.restrictive.path,
            ),
            (
              obstacle: OnboardingObstacle.lostMotivation,
              titleKey: 'onboarding.obstacle_motivation',
              iconPath: Assets.images.motivation.path,
            ),
            (
              obstacle: OnboardingObstacle.noTimeToCook,
              titleKey: 'onboarding.obstacle_time_cook',
              iconPath: Assets.images.timeCook.path,
            ),
            (
              obstacle: OnboardingObstacle.tooConfusing,
              titleKey: 'onboarding.obstacle_confusing',
              iconPath: Assets.images.confusing.path,
            ),
            (
              obstacle: OnboardingObstacle.lifeGotBusy,
              titleKey: 'onboarding.obstacle_busy',
              iconPath: Assets.images.busy.path,
            ),
            (
              obstacle: OnboardingObstacle.hitPlateau,
              titleKey: 'onboarding.obstacle_plateau',
              iconPath: Assets.images.pleteu.path,
            ),
          ];

  void onBack() {
    context.pop();
  }

  Future<void> onObstacleSelected(OnboardingObstacle obstacle) async {
    context.read<ObstaclesBloc>().add(ObstacleSelected(obstacle));
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    await context.push(RoutePaths.obstacleHighlight.path);
  }
}
