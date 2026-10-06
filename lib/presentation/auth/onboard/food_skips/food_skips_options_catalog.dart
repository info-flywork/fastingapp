import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/bloc/food_skips_bloc.dart';

/// Onboarding + Edit Profile ortak atlanan yiyecekler.
abstract final class FoodSkipsOptionsCatalog {
  static List<({OnboardingFoodSkip food, String titleKey, String imagePath})>
  get items => [
    (
      food: OnboardingFoodSkip.mushrooms,
      titleKey: 'onboarding.food_skip_mushrooms',
      imagePath: AppImages.mushroom.path,
    ),
    (
      food: OnboardingFoodSkip.olives,
      titleKey: 'onboarding.food_skip_olives',
      imagePath: AppImages.olives.path,
    ),
    (
      food: OnboardingFoodSkip.seafood,
      titleKey: 'onboarding.food_skip_seafood',
      imagePath: AppImages.seefood.path,
    ),
    (
      food: OnboardingFoodSkip.onions,
      titleKey: 'onboarding.food_skip_onions',
      imagePath: AppImages.onion.path,
    ),
    (
      food: OnboardingFoodSkip.broccoli,
      titleKey: 'onboarding.food_skip_broccoli',
      imagePath: AppImages.brocolies.path,
    ),
    (
      food: OnboardingFoodSkip.tooSpicy,
      titleKey: 'onboarding.food_skip_too_spicy',
      imagePath: AppImages.toospicy.path,
    ),
    (
      food: OnboardingFoodSkip.dairy,
      titleKey: 'onboarding.food_skip_dairy',
      imagePath: AppImages.dairy.path,
    ),
    (
      food: OnboardingFoodSkip.nuts,
      titleKey: 'onboarding.food_skip_nuts',
      imagePath: AppImages.nuts.path,
    ),
    (
      food: OnboardingFoodSkip.beans,
      titleKey: 'onboarding.food_skip_beans',
      imagePath: AppImages.beans.path,
    ),
    (
      food: OnboardingFoodSkip.eggplant,
      titleKey: 'onboarding.food_skip_eggplant',
      imagePath: AppImages.eggplant.path,
    ),
  ];

  static String titleKeyFor(OnboardingFoodSkip food) {
    return items.firstWhere((e) => e.food == food).titleKey;
  }
}
