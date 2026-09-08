part of '../diet_view.dart';

mixin DietViewMixin on State<DietView> {
  List<
      ({
        OnboardingDiet diet,
        String titleKey,
        String subtitleKey,
        String imagePath,
      })> get dietOptions => [
        (
          diet: OnboardingDiet.everything,
          titleKey: 'onboarding.diet_everything_title',
          subtitleKey: 'onboarding.diet_everything_subtitle',
          imagePath: Assets.images.everything.path,
        ),
        (
          diet: OnboardingDiet.vegetarian,
          titleKey: 'onboarding.diet_vegetarian_title',
          subtitleKey: 'onboarding.diet_vegetarian_subtitle',
          imagePath: Assets.images.vegetarian.path,
        ),
        (
          diet: OnboardingDiet.pescatarian,
          titleKey: 'onboarding.diet_pescatarian_title',
          subtitleKey: 'onboarding.diet_pescatarian_subtitle',
          imagePath: Assets.images.pescatarian.path,
        ),
        (
          diet: OnboardingDiet.vegan,
          titleKey: 'onboarding.diet_vegan_title',
          subtitleKey: 'onboarding.diet_vegan_subtitle',
          imagePath: Assets.images.plant.path,
        ),
        (
          diet: OnboardingDiet.lowCarb,
          titleKey: 'onboarding.diet_low_carb_title',
          subtitleKey: 'onboarding.diet_low_carb_subtitle',
          imagePath: Assets.images.lawCarb.path,
        ),
        (
          diet: OnboardingDiet.mediterranean,
          titleKey: 'onboarding.diet_mediterranean_title',
          subtitleKey: 'onboarding.diet_mediterranean_subtitle',
          imagePath: Assets.images.mediterrian.path,
        ),
      ];

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
