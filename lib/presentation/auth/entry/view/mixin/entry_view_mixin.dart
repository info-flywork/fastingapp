part of '../entry_view.dart';

mixin EntryViewMixin on State<EntryView> {
  void onGetStarted() {
    context.go(RoutePaths.onboarding.path);
  }

  void onAlreadyHaveAccount() {
    context.go(RoutePaths.welcome.path);
  }
}
