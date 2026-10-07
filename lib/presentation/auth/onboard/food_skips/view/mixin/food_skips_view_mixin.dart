part of '../food_skips_view.dart';

mixin FoodSkipsViewMixin on State<FoodSkipsView> {
  void onBack() {
    context.pop();
  }

  void onFoodToggled(OnboardingFoodSkip food) {
    context.read<FoodSkipsBloc>().add(FoodSkipToggled(food));
  }

  void onContinue() {
    final skips = context.read<FoodSkipsBloc>().state.selected;
    getIt<OnboardingDraft>().foodSkips = {...skips};
    context.push(
      RoutePaths.notedHighlight.path,
      extra: widget.prefs.copyWith(skips: skips),
    );
  }
}
