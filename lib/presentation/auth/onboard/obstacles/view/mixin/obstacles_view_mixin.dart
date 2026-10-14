part of '../obstacles_view.dart';

mixin ObstaclesViewMixin on State<ObstaclesView> {
  List<({OnboardingObstacle obstacle, String titleKey, String iconPath})>
  get obstacleOptions => [
    (
      obstacle: OnboardingObstacle.tooRestrictive,
      titleKey: 'onboarding.obstacle_restrictive',
      iconPath: AppImages.restrictive.path,
    ),
    (
      obstacle: OnboardingObstacle.lostMotivation,
      titleKey: 'onboarding.obstacle_motivation',
      iconPath: AppImages.motivation.path,
    ),
    (
      obstacle: OnboardingObstacle.noTimeToCook,
      titleKey: 'onboarding.obstacle_time_cook',
      iconPath: AppImages.timeCook.path,
    ),
    (
      obstacle: OnboardingObstacle.tooConfusing,
      titleKey: 'onboarding.obstacle_confusing',
      iconPath: AppImages.confusing.path,
    ),
    (
      obstacle: OnboardingObstacle.lifeGotBusy,
      titleKey: 'onboarding.obstacle_busy',
      iconPath: AppImages.busy.path,
    ),
    (
      obstacle: OnboardingObstacle.hitPlateau,
      titleKey: 'onboarding.obstacle_plateau',
      iconPath: AppImages.pleteu.path,
    ),
  ];

  void onBack() {
    context.pop();
  }

  void onObstacleToggled(OnboardingObstacle obstacle) {
    context.read<ObstaclesBloc>().add(ObstacleToggled(obstacle));
  }

  /// Birden çok engel seçilebilir ("uyanların hepsini seç").
  Future<void> onContinue() async {
    final selected = context.read<ObstaclesBloc>().state.selected;
    if (selected.isEmpty) return;
    getIt<OnboardingDraft>().obstacles = {...selected};
    await context.push(RoutePaths.obstacleHighlight.path);
  }
}
