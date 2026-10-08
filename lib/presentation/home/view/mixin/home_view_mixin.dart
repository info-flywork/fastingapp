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

  void onMealRecordsTapped() {
    context.pushNamed(RoutePaths.mealRecords.name);
  }

  void onHungerTrackerTapped() {
    context.pushNamed(RoutePaths.hungerTracker.name);
  }

  Future<void> onWeightEditTapped() async {
    await AppDialogs.instance.showEditWeight(
      context,
      initialWeightKg: switch (context.read<HomeBloc>().state) {
        HomeLoaded(:final summary) =>
          summary?.weightCurrentKg ?? HomeWeightCard.fallbackKg,
        _ => HomeWeightCard.fallbackKg,
      },
    );
  }
}
