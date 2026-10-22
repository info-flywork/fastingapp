import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_option_card.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_progress_header.dart';
import 'package:fastingapp/domain/onboarding/onboarding_draft.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/obstacles/bloc/obstacles_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'mixin/obstacles_view_mixin.dart';
part 'widgets/obstacles_options.dart';

/// Onboarding: geçen sefer ne engel oldu?
final class ObstaclesView extends StatefulWidget {
  const ObstaclesView({super.key});

  @override
  State<ObstaclesView> createState() => _ObstaclesViewState();
}

class _ObstaclesViewState extends State<ObstaclesView> with ObstaclesViewMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorName.colorWhite,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OnboardingProgressHeader(
                      fromProgress: 0.70,
                      targetProgress: 0.80,
                      onBack: onBack,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'onboarding.obstacles_title'.tr(),
                      style: AppTextStyles.onboardingTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'onboarding.obstacles_subtitle'.tr(),
                      style: AppTextStyles.onboardingSubtitle,
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<ObstaclesBloc, ObstaclesState>(
                      builder: (context, state) {
                        return ObstaclesOptions(
                          items: obstacleOptions,
                          selected: state.selected,
                          onToggle: onObstacleToggled,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: BlocBuilder<ObstaclesBloc, ObstaclesState>(
                builder: (context, state) {
                  return AppButton(
                    label: 'onboarding.continue'.tr(),
                    isEnabled: state.hasSelection,
                    onPressed: onContinue,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
