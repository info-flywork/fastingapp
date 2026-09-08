import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_highlight_view.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_journey_card.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/starting_point/starting_point_nav_args.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'mixin/doable_highlight_view_mixin.dart';

/// Starting point sonrası "Totally doable" highlight.
final class DoableHighlightView extends StatefulWidget {
  const DoableHighlightView({required this.args, super.key});

  final StartingPointNavArgs args;

  @override
  State<DoableHighlightView> createState() => _DoableHighlightViewState();
}

class _DoableHighlightViewState extends State<DoableHighlightView>
    with DoableHighlightViewMixin {
  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    return OnboardingHighlightView(
      mediaPath: Assets.gifs.mascotCelebration.path,
      title: 'onboarding.totally_doable'.tr(),
      subtitle: Text.rich(
        TextSpan(
          style: AppTextStyles.highlightSubtitle,
          children: [
            TextSpan(text: 'onboarding.doable_subtitle_before'.tr()),
            TextSpan(
              text: 'onboarding.doable_subtitle_kg'.tr(
                args: [formatDeltaKg(args.deltaKg)],
              ),
              style: AppTextStyles.highlightSubtitle.copyWith(
                fontWeight: FontWeight.w700,
                color: ColorName.colorWhite,
              ),
            ),
            TextSpan(text: 'onboarding.doable_subtitle_after'.tr()),
          ],
        ),
        textAlign: TextAlign.center,
      ),
      middle: OnboardingJourneyCard(
        currentWeightKg: args.weightKg,
        goalWeightKg: args.goalWeightKg,
        targetProgress: journeyProgressFor(
          currentKg: args.weightKg,
          goalKg: args.goalWeightKg,
        ),
        footer: 'onboarding.journey_starts_here'.tr(),
      ),
      buttonLabel: 'onboarding.lets_keep_going'.tr(),
      onContinue: onContinue,
    );
  }
}
