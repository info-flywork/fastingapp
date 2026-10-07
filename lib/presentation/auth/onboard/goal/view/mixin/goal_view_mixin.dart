part of '../goal_view.dart';

mixin GoalViewMixin on State<GoalView> {
  void onBack() {
    context.go(RoutePaths.entry.path);
  }

  Future<void> onGoalSelected(OnboardingGoal goal) async {
    context.read<GoalBloc>().add(GoalSelected(goal));
    getIt<OnboardingDraft>().goal = goal;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    await context.push(RoutePaths.goalHighlight.path);
  }
}
