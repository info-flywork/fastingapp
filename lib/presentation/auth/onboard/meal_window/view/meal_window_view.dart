import 'package:fastingapp/domain/onboarding/onboarding_draft.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_progress_header.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_time_picker.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/meal_window/bloc/meal_window_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'mixin/meal_window_view_mixin.dart';

/// Onboarding: yemek penceresi başlangıç / bitiş saati.
final class MealWindowView extends StatefulWidget {
  const MealWindowView({super.key});

  @override
  State<MealWindowView> createState() => _MealWindowViewState();
}

class _MealWindowViewState extends State<MealWindowView>
    with MealWindowViewMixin {
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
                      fromProgress: 0.95,
                      targetProgress: 1.0,
                      onBack: onBack,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'onboarding.meal_window_title'.tr(),
                      style: AppTextStyles.onboardingTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'onboarding.meal_window_subtitle'.tr(),
                      style: AppTextStyles.onboardingSubtitle,
                    ),
                    const SizedBox(height: 32),
                    BlocBuilder<MealWindowBloc, MealWindowState>(
                      builder: (context, state) {
                        return Column(
                          children: [
                            OnboardingTimePicker(
                              label: 'onboarding.meal_window_start'.tr(),
                              hour: state.startHour,
                              minute: state.startMinute,
                              onHourChanged: onStartHourChanged,
                              onMinuteChanged: onStartMinuteChanged,
                            ),
                            const SizedBox(height: 24),
                            OnboardingTimePicker(
                              label: 'onboarding.meal_window_finish'.tr(),
                              hour: state.endHour,
                              minute: state.endMinute,
                              onHourChanged: onEndHourChanged,
                              onMinuteChanged: onEndMinuteChanged,
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
