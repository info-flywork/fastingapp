part of '../fasting_reason_view.dart';

mixin FastingReasonViewMixin on State<FastingReasonView> {
  List<({OnboardingFastingReason reason, String titleKey, String iconPath})>
      get reasonOptions => [
            (
              reason: OnboardingFastingReason.specialDate,
              titleKey: 'onboarding.fasting_reason_special_date',
              iconPath: Assets.images.date.path,
            ),
            (
              reason: OnboardingFastingReason.trip,
              titleKey: 'onboarding.fasting_reason_trip',
              iconPath: Assets.images.trip.path,
            ),
            (
              reason: OnboardingFastingReason.healthLongevity,
              titleKey: 'onboarding.fasting_reason_health',
              iconPath: Assets.images.healty.path,
            ),
            (
              reason: OnboardingFastingReason.confidence,
              titleKey: 'onboarding.fasting_reason_confidence',
              iconPath: Assets.images.confidence.path,
            ),
          ];

  String formatTargetDate(DateTime date) {
    return DateFormat('MMM d, yyyy', context.locale.toString()).format(date);
  }

  void onBack() {
    context.pop();
  }

  void onReasonSelected(OnboardingFastingReason reason) {
    context.read<FastingReasonBloc>().add(FastingReasonSelected(reason));
  }

  void onContinue() {
    final reason = context.read<FastingReasonBloc>().state.selected;
    if (reason == null) return;
    context.push(RoutePaths.reasonHighlight.path, extra: reason);
  }
}
