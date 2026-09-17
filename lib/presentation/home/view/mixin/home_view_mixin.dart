part of '../home_view.dart';

/// Home ekranı snackbar / navigasyon / side-effect yardımcıları. (Doküman 5.5)
mixin HomeViewMixin on State<HomeView> {
  void showErrorSnackbar(String message) {
    AppSnackbar.show(
      context: context,
      text: message,
      type: SnackBarType.failure,
    );
  }

  void onRetry() {
    context.read<HomeBloc>().add(const HomeStarted());
  }

  void onPremiumTapped() {
    context.read<HomeBloc>().add(const HomePremiumTapped());
  }

  void onChatTapped() {
    context.pushNamed(RoutePaths.chat.name);
  }

  void onWaterTapped() {
    context.pushNamed(RoutePaths.water.name);
  }

  void onStepsTapped() {
    context.pushNamed(RoutePaths.steps.name);
  }

  void onWeightTapped() {
    context.pushNamed(RoutePaths.bodyHistory.name);
  }
}
