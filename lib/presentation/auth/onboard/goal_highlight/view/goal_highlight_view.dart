import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_highlight_view.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_social_proof_card.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Hedef seçimi sonrası highlight — diğer highlight sayfalarının şablonu.
final class GoalHighlightView extends StatelessWidget {
  const GoalHighlightView({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingHighlightView(
      mediaPath: Assets.gifs.mascotCalendar.path,
      title: 'onboarding.great_choice'.tr(),
      subtitle: Text(
        'onboarding.habit_highlight_subtitle'.tr(),
        textAlign: TextAlign.center,
      ),
      middle: OnboardingSocialProofCard(
        metric: 'onboarding.social_proof_metric'.tr(),
        caption: 'onboarding.social_proof_caption'.tr(),
      ),
      buttonLabel: 'onboarding.lets_keep_going'.tr(),
      onContinue: () => context.push(RoutePaths.aboutYou.path),
    );
  }
}
