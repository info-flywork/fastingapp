import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_highlight_view.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_info_chip.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/food_prefs_nav_args.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/bloc/food_skips_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'mixin/noted_highlight_view_mixin.dart';

/// Food prefs sonrası "Noted!" highlight.
final class NotedHighlightView extends StatefulWidget {
  const NotedHighlightView({required this.args, super.key});

  final FoodPrefsNavArgs args;

  @override
  State<NotedHighlightView> createState() => _NotedHighlightViewState();
}

class _NotedHighlightViewState extends State<NotedHighlightView>
    with NotedHighlightViewMixin {
  @override
  Widget build(BuildContext context) {
    return OnboardingHighlightView(
      mediaPath: Assets.gifs.mascotWriting.path,
      gradientColors: const [
        ColorName.colorNotedGradientTop,
        ColorName.colorNotedGradientBottom,
      ],
      title: 'onboarding.noted_title'.tr(),
      subtitle: buildNotedSubtitle(widget.args.skips),
      middle: OnboardingInfoChip(
        leading: Text(
          '🥗',
          style: TextStyle(
            fontSize: 16,
            fontFamilyFallback: const [
              'Apple Color Emoji',
              'Noto Color Emoji',
              'Segoe UI Emoji',
            ],
          ),
        ),
        label: summaryChipLabel(
          favourites: widget.args.loves.length,
          skips: widget.args.skips.length,
        ),
        labelStyle: AppTextStyles.notedSummaryChip,
      ),
      buttonLabel: 'onboarding.lets_keep_going'.tr(),
      onContinue: onContinue,
    );
  }
}
