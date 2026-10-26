import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/onboarding/fasting_plan_options_list.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_progress_header.dart';
import 'package:fastingapp/domain/onboarding/onboarding_draft.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/bloc/fasting_plan_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/fasting_plan_options_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'mixin/fasting_plan_view_mixin.dart';

/// Onboarding: oruç planı seçimi.
final class FastingPlanView extends StatefulWidget {
  const FastingPlanView({super.key});

  @override
  State<FastingPlanView> createState() => _FastingPlanViewState();
}

class _FastingPlanViewState extends State<FastingPlanView>
    with FastingPlanViewMixin {
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
                      fromProgress: 0.90,
                      targetProgress: 0.95,
                      onBack: onBack,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'onboarding.fasting_plan_title'.tr(),
                      style: AppTextStyles.onboardingTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'onboarding.fasting_plan_subtitle'.tr(),
                      style: AppTextStyles.onboardingSubtitle,
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<FastingPlanBloc, FastingPlanState>(
                      builder: (context, state) {
                        return FastingPlanOptionsList(
                          selected: state.selected,
                          onSelected: onPlanSelected,
                          showFooter: false,
                          age: getIt<OnboardingDraft>().age,
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
              child: BlocBuilder<FastingPlanBloc, FastingPlanState>(
                buildWhen: (prev, next) => prev.selected != next.selected,
                builder: (context, state) {
                  return AppButton(
                    label: 'onboarding.continue'.tr(),
                    isEnabled: state.selected != null,
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
