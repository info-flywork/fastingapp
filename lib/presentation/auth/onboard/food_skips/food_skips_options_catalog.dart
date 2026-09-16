import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/bloc/food_skips_bloc.dart';

/// Onboarding + Edit Profile ortak atlanan yiyecekler.
abstract final class FoodSkipsOptionsCatalog {
  static List<({OnboardingFoodSkip food, String titleKey, String imagePath})>
      get items => [
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
              food: OnboardingFoodSkip.seafood,
              titleKey: 'onboarding.food_skip_seafood',
              imagePath: Assets.images.seefood.path,
            ),
            (
              food: OnboardingFoodSkip.onions,
              titleKey: 'onboarding.food_skip_onions',
              imagePath: Assets.images.onion.path,
            ),
            (
              food: OnboardingFoodSkip.broccoli,
              titleKey: 'onboarding.food_skip_broccoli',
              imagePath: Assets.images.brocolies.path,
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

  static String titleKeyFor(OnboardingFoodSkip food) {
    return items.firstWhere((e) => e.food == food).titleKey;
  }
}
