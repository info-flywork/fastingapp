import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_highlight_view.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_info_chip.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Obstacles sonrası "It wasn't you" highlight.
final class ObstacleHighlightView extends StatelessWidget {
  const ObstacleHighlightView({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingHighlightView(
      mediaPath: Assets.gifs.mascotBroccoli.path,
      title: 'onboarding.obstacle_highlight_title'.tr(),
      subtitle: Text(
        'onboarding.obstacle_highlight_subtitle'.tr(),
        textAlign: TextAlign.center,
      ),
      middle: Column(
        children: [
          OnboardingInfoChip(
            expand: true,
            leading: Text('✓', style: AppTextStyles.infoChipLabel),
            label: 'onboarding.obstacle_highlight_point_1'.tr(),
          ),
          const SizedBox(height: 12),
          OnboardingInfoChip(
            expand: true,
            leading: Text('✓', style: AppTextStyles.infoChipLabel),
            label: 'onboarding.obstacle_highlight_point_2'.tr(),
          ),
        ],
      ),
      buttonLabel: 'onboarding.im_in'.tr(),
      onContinue: () => context.push(RoutePaths.fastingReason.path),
    );
  }
}
