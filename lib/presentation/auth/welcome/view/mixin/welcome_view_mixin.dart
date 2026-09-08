part of '../welcome_view.dart';

/// Karşılama ekranı navigasyon ve snackbar yardımcıları. (Doküman 5.5)
mixin WelcomeViewMixin on State<WelcomeView> {
  void onStateChanged(BuildContext context, WelcomeState state) {
    switch (state) {
      case WelcomeSuccess(:final navigateTo):
        context.go(navigateTo);
      case WelcomeError(:final message):
        AppSnackbar.show(
          context: context,
          text: message,
          type: SnackBarType.failure,
        );
      case WelcomeInitial():
      case WelcomeLoading():
        break;
    }
  }
}
