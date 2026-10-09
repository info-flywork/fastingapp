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
    final home = context.read<HomeBloc>().state;
    final summary = home is HomeLoaded ? home.summary : null;
    context.pushNamed(
      RoutePaths.water.name,
      extra: {
        'initialMl': summary?.waterMl ?? 0,
        'dailyGoalMl': summary?.waterGoalMl ?? 2500,
      },
    );
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

  /// Kalem: yeni kilo kaydı (`POST /weights`), ardından özet ve profil tazelenir.
  Future<void> onWeightEditTapped() => WeightEntryFlow.open(
    context,
    currentKg: switch (context.read<HomeBloc>().state) {
      HomeLoaded(:final summary) => summary?.weightCurrentKg,
      _ => null,
    },
  );
}
