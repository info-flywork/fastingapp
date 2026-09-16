import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/about_you/bloc/about_you_bloc.dart';

/// Onboarding + Edit Profile ortak cinsiyet seçenekleri.
abstract final class GenderOptionsCatalog {
  static List<({OnboardingGender gender, String titleKey, String iconPath})>
      get items => [
            (
              gender: OnboardingGender.woman,
              titleKey: 'onboarding.gender_woman',
              iconPath: Assets.images.woman.path,
            ),
            (
              gender: OnboardingGender.man,
              titleKey: 'onboarding.gender_man',
              iconPath: Assets.images.man.path,
            ),
            (
              gender: OnboardingGender.nonBinary,
              titleKey: 'onboarding.gender_non_binary',
              iconPath: Assets.images.nonBinary.path,
            ),
            (
              gender: OnboardingGender.preferNotToSay,
              titleKey: 'onboarding.gender_prefer_not',
              iconPath: Assets.images.preferNot.path,
            ),
          ];

  static String titleKeyFor(OnboardingGender gender) {
    return items.firstWhere((e) => e.gender == gender).titleKey;
  }
}
