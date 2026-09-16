part of '../diet_view.dart';

mixin DietViewMixin on State<DietView> {
  void onBack() {
    context.pop();
  }

  void onDietSelected(OnboardingDiet diet) {
    context.read<DietBloc>().add(DietSelected(diet));
  }

  void onContinue() {
    context.push(RoutePaths.foodLoves.path);
  }
}
