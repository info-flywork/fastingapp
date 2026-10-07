part of '../food_loves_view.dart';

mixin FoodLovesViewMixin on State<FoodLovesView> {
  void onBack() {
    context.pop();
  }

  void onFoodToggled(OnboardingFoodLove food) {
    context.read<FoodLovesBloc>().add(FoodLoveToggled(food));
  }

  void onContinue() {
    final loves = context.read<FoodLovesBloc>().state.selected;
    getIt<OnboardingDraft>().foodLoves = {...loves};
    context.push(
      RoutePaths.foodSkips.path,
      extra: FoodPrefsNavArgs(loves: loves),
    );
  }
}
