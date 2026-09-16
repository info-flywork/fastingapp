import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/food_loves/bloc/food_loves_bloc.dart';

/// Onboarding + Edit Profile ortak tercih edilen yiyecekler.
abstract final class FoodLovesOptionsCatalog {
  static List<({OnboardingFoodLove food, String titleKey, String imagePath})>
      get items => [
            (
              food: OnboardingFoodLove.chicken,
              titleKey: 'onboarding.food_chicken',
              imagePath: Assets.images.chicken.path,
            ),
            (
              food: OnboardingFoodLove.fish,
              titleKey: 'onboarding.food_fish',
              imagePath: Assets.images.fish.path,
            ),
            (
              food: OnboardingFoodLove.rice,
              titleKey: 'onboarding.food_rice',
              imagePath: Assets.images.rice.path,
            ),
            (
              food: OnboardingFoodLove.redMeat,
              titleKey: 'onboarding.food_red_meat',
              imagePath: Assets.images.meat.path,
            ),
            (
              food: OnboardingFoodLove.pasta,
              titleKey: 'onboarding.food_pasta',
              imagePath: Assets.images.pasta.path,
            ),
            (
              food: OnboardingFoodLove.salads,
              titleKey: 'onboarding.food_salads',
              imagePath: Assets.images.salata.path,
            ),
            (
              food: OnboardingFoodLove.cheese,
              titleKey: 'onboarding.food_cheese',
              imagePath: Assets.images.cheese.path,
            ),
            (
              food: OnboardingFoodLove.eggs,
              titleKey: 'onboarding.food_eggs',
              imagePath: Assets.images.eggs.path,
            ),
            (
              food: OnboardingFoodLove.spicy,
              titleKey: 'onboarding.food_spicy',
              imagePath: Assets.images.spicy.path,
            ),
            (
              food: OnboardingFoodLove.noodles,
              titleKey: 'onboarding.food_noodles',
              imagePath: Assets.images.noodles.path,
            ),
            (
              food: OnboardingFoodLove.fruit,
              titleKey: 'onboarding.food_fruit',
              imagePath: Assets.images.fruit.path,
            ),
            (
              food: OnboardingFoodLove.avocado,
              titleKey: 'onboarding.food_avocado',
              imagePath: Assets.images.avacado.path,
            ),
            (
              food: OnboardingFoodLove.sweets,
              titleKey: 'onboarding.food_sweets',
              imagePath: Assets.images.sweethies.path,
            ),
          ];

  static String titleKeyFor(OnboardingFoodLove food) {
    return items.firstWhere((e) => e.food == food).titleKey;
  }
}
