part of '../fasting_plan_view.dart';

mixin FastingPlanViewMixin on State<FastingPlanView> {
  void onBack() {
    context.pop();
  }

  void onPlanSelected(OnboardingFastingPlan plan) {
    context.read<FastingPlanBloc>().add(FastingPlanSelected(plan));
  }

  void onContinue() {
    final plan = context.read<FastingPlanBloc>().state.selected;
    getIt<OnboardingDraft>().plan = plan;
    if (plan == null) return;
    context.push(RoutePaths.planHighlight.path, extra: plan);
  }
}
