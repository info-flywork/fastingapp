part of '../hunger_success_view.dart';

mixin HungerSuccessViewMixin on State<HungerSuccessView> {
  void onInsightsTapped() {
    // Insights — sonraki adım.
  }

  void onBackToHomeTapped() {
    context.go(RoutePaths.home.path);
  }
}
