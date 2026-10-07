part of '../diet_view.dart';

mixin DietViewMixin on State<DietView> {
  void onBack() {
    context.pop();
  }

  void onDietSelected(OnboardingDiet diet) {
    context.read<DietBloc>().add(DietSelected(diet));
  }

  void onContinue() {
    getIt<OnboardingDraft>().diet = context.read<DietBloc>().state.selected;
    context.push(RoutePaths.foodLoves.path);
  }
}
