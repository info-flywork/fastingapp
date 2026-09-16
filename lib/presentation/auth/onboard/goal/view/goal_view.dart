import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/onboarding/goal_options_list.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_progress_header.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/goal/bloc/goal_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'mixin/goal_view_mixin.dart';

/// Onboarding ilk adım: hedef seçimi.
final class GoalView extends StatefulWidget {
  const GoalView({super.key});

  @override
  State<GoalView> createState() => _GoalViewState();
}

class _GoalViewState extends State<GoalView> with GoalViewMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorName.colorWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingProgressHeader(targetProgress: 0.10, onBack: onBack),
              const SizedBox(height: 40),
              Text(
                'onboarding.goal_title'.tr(),
                style: AppTextStyles.onboardingTitle,
              ),
              const SizedBox(height: 8),
              Text(
                'onboarding.goal_subtitle'.tr(),
                style: AppTextStyles.onboardingSubtitle,
              ),
              const SizedBox(height: 24),
              BlocBuilder<GoalBloc, GoalState>(
                builder: (context, state) {
                  return GoalOptionsList(
                    selected: state.selected,
                    onSelected: onGoalSelected,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
