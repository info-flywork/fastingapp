part of '../weight_history_view.dart';

mixin WeightHistoryViewMixin on State<WeightHistoryView> {
  List<
    ({
      OnboardingWeightHistory history,
      String titleKey,
      String subtitleKey,
      String iconPath,
    })
  >
  get weightHistoryOptions => [
    (
      history: OnboardingWeightHistory.manyTimes,
      titleKey: 'onboarding.weight_history_many_title',
      subtitleKey: 'onboarding.weight_history_many_subtitle',
      iconPath: AppImages.weigher.path,
    ),
    (
      history: OnboardingWeightHistory.onceOrTwice,
      titleKey: 'onboarding.weight_history_once_title',
      subtitleKey: 'onboarding.weight_history_once_subtitle',
      iconPath: AppImages.a1Or2.path,
    ),
    (
      history: OnboardingWeightHistory.firstTime,
      titleKey: 'onboarding.weight_history_first_title',
      subtitleKey: 'onboarding.weight_history_first_subtitle',
      iconPath: AppImages.plant.path,
    ),
  ];

  void onBack() {
    context.pop();
  }

  Future<void> onHistorySelected(OnboardingWeightHistory history) async {
    context.read<WeightHistoryBloc>().add(WeightHistorySelected(history));
    getIt<OnboardingDraft>().weightHistory = history;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    // Sıradaki onboarding adımı: engeller (ilk seferde de aynı akış).
    await context.push(RoutePaths.obstacles.path);
  }
}
