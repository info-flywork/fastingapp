part of '../food_skips_view.dart';

mixin FoodSkipsViewMixin on State<FoodSkipsView> {
  List<({OnboardingFoodSkip food, String titleKey, String imagePath})>
  get foodSkipOptions => [
    (
      food: OnboardingFoodSkip.mushrooms,
      titleKey: 'onboarding.food_skip_mushrooms',
      imagePath: Assets.images.mushroom.path,
    ),
    (
      food: OnboardingFoodSkip.olives,
      titleKey: 'onboarding.food_skip_olives',
      imagePath: Assets.images.olives.path,
    ),
    (
      food: OnboardingFoodSkip.onions,
      titleKey: 'onboarding.food_skip_onions',
      imagePath: Assets.images.onion.path,
    ),
    (
      food: OnboardingFoodSkip.seafood,
      titleKey: 'onboarding.food_skip_seafood',
      imagePath: Assets.images.seefood.path,
    ),

    (
      food: OnboardingFoodSkip.tooSpicy,
      titleKey: 'onboarding.food_skip_too_spicy',
      imagePath: Assets.images.toospicy.path,
    ),
    (
      food: OnboardingFoodSkip.dairy,
      titleKey: 'onboarding.food_skip_dairy',
      imagePath: Assets.images.dairy.path,
    ),
    (
      food: OnboardingFoodSkip.nuts,
      titleKey: 'onboarding.food_skip_nuts',
      imagePath: Assets.images.nuts.path,
    ),
    (
      food: OnboardingFoodSkip.beans,
      titleKey: 'onboarding.food_skip_beans',
      imagePath: Assets.images.beans.path,
    ),
    (
      food: OnboardingFoodSkip.eggplant,
      titleKey: 'onboarding.food_skip_eggplant',
      imagePath: Assets.images.eggplant.path,
    ),
  ];

  void onBack() {
    context.pop();
  }

  void onFoodToggled(OnboardingFoodSkip food) {
    context.read<FoodSkipsBloc>().add(FoodSkipToggled(food));
  }

  void onContinue() {
    final skips = context.read<FoodSkipsBloc>().state.selected;
    context.push(
      RoutePaths.notedHighlight.path,
      extra: widget.prefs.copyWith(skips: skips),
    );
  }
}
