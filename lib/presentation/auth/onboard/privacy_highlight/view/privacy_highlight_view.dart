import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_highlight_view.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_info_chip.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// About you sonrası gizlilik highlight ekranı.
final class PrivacyHighlightView extends StatelessWidget {
  const PrivacyHighlightView({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingHighlightView(
      mediaPath: Assets.gifs.mascotHearts.path,
      title: 'onboarding.lovely_to_meet_you'.tr(),
      subtitle: Text(
        'onboarding.privacy_highlight_subtitle'.tr(),
        textAlign: TextAlign.center,
      ),
      middle: OnboardingInfoChip(
        leading: const Text('🔒', style: TextStyle(fontSize: 16)),
        label: 'onboarding.privacy_chip'.tr(),
      ),
      buttonLabel: 'onboarding.lets_keep_going'.tr(),
      onContinue: () => context.push(RoutePaths.startingPoint.path),
    );
  }
}
