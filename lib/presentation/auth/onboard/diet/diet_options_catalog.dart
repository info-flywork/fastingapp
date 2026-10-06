import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/presentation/auth/onboard/diet/bloc/diet_bloc.dart';

/// Onboarding + Edit Profile ortak diyet seçenekleri.
abstract final class DietOptionsCatalog {
  static List<
    ({
      OnboardingDiet diet,
      String titleKey,
      String subtitleKey,
      String imagePath,
    })
  >
  get items => [
    (
      diet: OnboardingDiet.everything,
      titleKey: 'onboarding.diet_everything_title',
      subtitleKey: 'onboarding.diet_everything_subtitle',
      imagePath: AppImages.everything.path,
    ),
    (
      diet: OnboardingDiet.vegetarian,
      titleKey: 'onboarding.diet_vegetarian_title',
      subtitleKey: 'onboarding.diet_vegetarian_subtitle',
      imagePath: AppImages.vegetarian.path,
    ),
    (
      diet: OnboardingDiet.pescatarian,
      titleKey: 'onboarding.diet_pescatarian_title',
      subtitleKey: 'onboarding.diet_pescatarian_subtitle',
      imagePath: AppImages.pescatarian.path,
    ),
    (
      diet: OnboardingDiet.vegan,
      titleKey: 'onboarding.diet_vegan_title',
      subtitleKey: 'onboarding.diet_vegan_subtitle',
      imagePath: AppImages.plant.path,
    ),
    (
      diet: OnboardingDiet.lowCarb,
      titleKey: 'onboarding.diet_low_carb_title',
      subtitleKey: 'onboarding.diet_low_carb_subtitle',
      imagePath: AppImages.lawCarb.path,
    ),
    (
      diet: OnboardingDiet.mediterranean,
      titleKey: 'onboarding.diet_mediterranean_title',
      subtitleKey: 'onboarding.diet_mediterranean_subtitle',
      imagePath: AppImages.mediterrian.path,
    ),
  ];

  static String titleKeyFor(OnboardingDiet diet) {
    return items.firstWhere((e) => e.diet == diet).titleKey;
  }
}
