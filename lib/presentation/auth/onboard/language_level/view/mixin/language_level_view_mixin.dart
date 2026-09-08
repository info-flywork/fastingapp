part of '../language_level_view.dart';

/// Onboarding navigasyon yardımcıları. (Doküman 5.5)
mixin LanguageLevelViewMixin on State<LanguageLevelView> {
  void onStateChanged(BuildContext context, LanguageLevelState state) {
    if (state is LanguageLevelCompleted) {
      context.go(RoutePaths.home.path);
    }
  }
}
