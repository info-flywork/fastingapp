part of '../fasting_plan_view.dart';

mixin FastingPlanViewMixin on State<FastingPlanView> {
  void onBack() {
    context.pop();
  }

  Future<void> onPlanSelected(OnboardingFastingPlan plan) async {
    final bloc = context.read<FastingPlanBloc>();
    if (!await FastingPlanOptionsCatalog.ensureUnlocked(plan)) return;
    bloc.add(FastingPlanSelected(plan));
  }

  void onContinue() {
    final selected = context.read<FastingPlanBloc>().state.selected;
    // Önceden seçilip yaş değişince uygunsuz kalan plan gönderilmez.
    final plan =
        selected != null &&
            FastingPlanOptionsCatalog.allowedFor(
              selected,
              getIt<OnboardingDraft>().age,
            ) &&
            (!FastingPlanOptionsCatalog.isPremiumPlan(selected) ||
                getIt<RevenueCatService>().isPremium.value)
        ? selected
        : null;
    getIt<OnboardingDraft>().plan = plan;
    if (plan == null) return;
    context.push(RoutePaths.planHighlight.path, extra: plan);
  }
}
