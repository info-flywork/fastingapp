part of '../about_you_view.dart';

mixin AboutYouViewMixin on State<AboutYouView> {
  List<({OnboardingGender gender, String titleKey, String iconPath})>
      get genderOptions => [
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

  void onBack() {
    context.pop();
  }

  Future<void> onGenderSelected(OnboardingGender gender) async {
    context.read<AboutYouBloc>().add(AboutYouGenderSelected(gender));
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    await context.push(RoutePaths.privacyHighlight.path);
  }
}
