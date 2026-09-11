import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_highlight_view.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_info_chip.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_reason/bloc/fasting_reason_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Fasting reason sonrası "Anchored" highlight.
final class ReasonHighlightView extends StatelessWidget {
  const ReasonHighlightView({
    required this.reason,
    super.key,
  });

  final OnboardingFastingReason reason;

  String get _subtitleKey => switch (reason) {
        OnboardingFastingReason.specialDate =>
          'onboarding.reason_highlight_subtitle_special_date',
        OnboardingFastingReason.trip =>
          'onboarding.reason_highlight_subtitle_trip',
        OnboardingFastingReason.healthLongevity =>
          'onboarding.reason_highlight_subtitle_health',
        OnboardingFastingReason.confidence =>
          'onboarding.reason_highlight_subtitle_confidence',
      };

  @override
  Widget build(BuildContext context) {
    return OnboardingHighlightView(
      mediaPath: Assets.gifs.mascotRing.path,
      title: 'onboarding.reason_highlight_title'.tr(),
      subtitle: Text(
        _subtitleKey.tr(),
        textAlign: TextAlign.center,
      ),
      middle: OnboardingInfoChip(
        expand: true,
        textAlign: TextAlign.center,
        label: 'onboarding.reason_highlight_quote'.tr(),
        labelStyle: AppTextStyles.infoChipLabel,
      ),
      buttonLabel: 'onboarding.continue'.tr(),
      onContinue: () => context.push(RoutePaths.fastingPlan.path),
    );
  }
}
