import 'package:fastingapp/domain/onboarding/onboarding_draft.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/onboarding/food_loves_options_list.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_progress_header.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/food_loves/bloc/food_loves_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/food_prefs_nav_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'mixin/food_loves_view_mixin.dart';

/// Onboarding: sevilen yiyecekler (çoklu seçim).
final class FoodLovesView extends StatefulWidget {
  const FoodLovesView({super.key});

  @override
  State<FoodLovesView> createState() => _FoodLovesViewState();
}

class _FoodLovesViewState extends State<FoodLovesView> with FoodLovesViewMixin {
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
                      fromProgress: 0.40,
                      targetProgress: 0.50,
                      onBack: onBack,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'onboarding.food_loves_title'.tr(),
                      style: AppTextStyles.onboardingTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'onboarding.food_loves_subtitle'.tr(),
                      style: AppTextStyles.onboardingSubtitle,
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<FoodLovesBloc, FoodLovesState>(
                      builder: (context, state) {
                        return FoodLovesOptionsList(
                          selected: state.selected,
                          onToggle: onFoodToggled,
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
              child: BlocBuilder<FoodLovesBloc, FoodLovesState>(
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
