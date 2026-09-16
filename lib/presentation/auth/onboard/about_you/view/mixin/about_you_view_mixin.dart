part of '../about_you_view.dart';

mixin AboutYouViewMixin on State<AboutYouView> {
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
