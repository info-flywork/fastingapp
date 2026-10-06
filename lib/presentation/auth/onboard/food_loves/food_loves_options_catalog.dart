import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/presentation/auth/onboard/food_loves/bloc/food_loves_bloc.dart';

/// Onboarding + Edit Profile ortak tercih edilen yiyecekler.
abstract final class FoodLovesOptionsCatalog {
  static List<({OnboardingFoodLove food, String titleKey, String imagePath})>
  get items => [
    (
      food: OnboardingFoodLove.chicken,
      titleKey: 'onboarding.food_chicken',
      imagePath: AppImages.chicken.path,
    ),
    (
      food: OnboardingFoodLove.fish,
      titleKey: 'onboarding.food_fish',
      imagePath: AppImages.fish.path,
    ),
    (
      food: OnboardingFoodLove.rice,
      titleKey: 'onboarding.food_rice',
      imagePath: AppImages.rice.path,
    ),
    (
      food: OnboardingFoodLove.redMeat,
      titleKey: 'onboarding.food_red_meat',
      imagePath: AppImages.meat.path,
    ),
    (
      food: OnboardingFoodLove.pasta,
      titleKey: 'onboarding.food_pasta',
      imagePath: AppImages.pasta.path,
    ),
    (
      food: OnboardingFoodLove.salads,
      titleKey: 'onboarding.food_salads',
      imagePath: AppImages.salata.path,
    ),
    (
      food: OnboardingFoodLove.cheese,
      titleKey: 'onboarding.food_cheese',
      imagePath: AppImages.cheese.path,
    ),
    (
      food: OnboardingFoodLove.eggs,
      titleKey: 'onboarding.food_eggs',
      imagePath: AppImages.eggs.path,
    ),
    (
      food: OnboardingFoodLove.spicy,
      titleKey: 'onboarding.food_spicy',
      imagePath: AppImages.spicy.path,
    ),
    (
      food: OnboardingFoodLove.noodles,
      titleKey: 'onboarding.food_noodles',
      imagePath: AppImages.noodles.path,
    ),
    (
      food: OnboardingFoodLove.fruit,
      titleKey: 'onboarding.food_fruit',
      imagePath: AppImages.fruit.path,
    ),
    (
      food: OnboardingFoodLove.avocado,
      titleKey: 'onboarding.food_avocado',
      imagePath: AppImages.avacado.path,
    ),
    (
      food: OnboardingFoodLove.sweets,
      titleKey: 'onboarding.food_sweets',
      imagePath: AppImages.sweethies.path,
    ),
  ];

  static String titleKeyFor(OnboardingFoodLove food) {
    return items.firstWhere((e) => e.food == food).titleKey;
  }
}
