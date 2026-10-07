import 'package:fastingapp/domain/onboarding/onboarding_draft.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_progress_header.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_stepper_field.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/starting_point/bloc/starting_point_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/starting_point/starting_point_nav_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'mixin/starting_point_view_mixin.dart';

/// Onboarding: kilo / hedef / boy / yaş.
final class StartingPointView extends StatefulWidget {
  const StartingPointView({super.key});

  @override
  State<StartingPointView> createState() => _StartingPointViewState();
}

class _StartingPointViewState extends State<StartingPointView>
    with StartingPointViewMixin {
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
                      fromProgress: 0.20,
                      targetProgress: 0.30,
                      onBack: onBack,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'onboarding.starting_point_title'.tr(),
                      style: AppTextStyles.onboardingTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'onboarding.starting_point_subtitle'.tr(),
                      style: AppTextStyles.onboardingSubtitle,
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<StartingPointBloc, StartingPointState>(
                      builder: (context, state) {
                        return Column(
                          children: [
                            OnboardingStepperField(
                              label: 'onboarding.current_weight'.tr(),
                              displayValue: state.weightKg.toStringAsFixed(1),
                              unit: 'onboarding.unit_kg'.tr(),
                              onDecrement: () => onWeightDelta(-0.5),
                              onIncrement: () => onWeightDelta(0.5),
                            ),
                            const SizedBox(height: 12),
                            OnboardingStepperField(
                              label: 'onboarding.goal_weight'.tr(),
                              displayValue: state.goalWeightKg.toStringAsFixed(
                                1,
                              ),
                              unit: 'onboarding.unit_kg'.tr(),
                              accentValue: true,
                              onDecrement: () => onGoalWeightDelta(-0.5),
                              onIncrement: () => onGoalWeightDelta(0.5),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OnboardingStepperField(
                                    label: 'onboarding.height'.tr(),
                                    displayValue: '${state.heightCm}',
                                    unit: 'onboarding.unit_cm'.tr(),
                                    onDecrement: () => onHeightDelta(-1),
                                    onIncrement: () => onHeightDelta(1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OnboardingStepperField(
                                    label: 'onboarding.age'.tr(),
                                    displayValue: '${state.age}',
                                    onDecrement: () => onAgeDelta(-1),
                                    onIncrement: () => onAgeDelta(1),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: AppButton(
                label: 'onboarding.get_started'.tr(),
                onPressed: onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
