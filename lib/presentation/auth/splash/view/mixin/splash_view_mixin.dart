part of '../splash_view.dart';

/// Splash navigasyon yardımcıları. (Doküman 5.5)
mixin SplashViewMixin on State<SplashView> {
  void onStateChanged(BuildContext context, SplashState state) {
    if (state is SplashNavigateTo) {
      context.go(state.destination);
    }
  }
}
