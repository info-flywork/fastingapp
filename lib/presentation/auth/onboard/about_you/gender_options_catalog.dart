import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/presentation/auth/onboard/about_you/bloc/about_you_bloc.dart';

/// Onboarding + Edit Profile ortak cinsiyet seçenekleri.
abstract final class GenderOptionsCatalog {
  static List<({OnboardingGender gender, String titleKey, String iconPath})>
  get items => [
    (
      gender: OnboardingGender.woman,
      titleKey: 'onboarding.gender_woman',
      iconPath: AppImages.woman.path,
    ),
    (
      gender: OnboardingGender.man,
      titleKey: 'onboarding.gender_man',
      iconPath: AppImages.man.path,
    ),
    (
      gender: OnboardingGender.nonBinary,
      titleKey: 'onboarding.gender_non_binary',
      iconPath: AppImages.nonBinary.path,
    ),
    (
      gender: OnboardingGender.preferNotToSay,
      titleKey: 'onboarding.gender_prefer_not',
      iconPath: AppImages.preferNot.path,
    ),
  ];

  static String titleKeyFor(OnboardingGender gender) {
    return items.firstWhere((e) => e.gender == gender).titleKey;
  }
}
