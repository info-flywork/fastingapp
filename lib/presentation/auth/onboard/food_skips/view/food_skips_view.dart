import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/onboarding/food_skips_options_list.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_progress_header.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/food_prefs_nav_args.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/bloc/food_skips_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'mixin/food_skips_view_mixin.dart';

/// Onboarding: istemediği yiyecekler (opsiyonel, çoklu seçim).
final class FoodSkipsView extends StatefulWidget {
  const FoodSkipsView({this.prefs = const FoodPrefsNavArgs(), super.key});

  final FoodPrefsNavArgs prefs;

  @override
  State<FoodSkipsView> createState() => _FoodSkipsViewState();
}

class _FoodSkipsViewState extends State<FoodSkipsView> with FoodSkipsViewMixin {
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
                      fromProgress: 0.50,
                      targetProgress: 0.60,
                      onBack: onBack,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'onboarding.food_skips_title'.tr(),
                      style: AppTextStyles.onboardingTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'onboarding.food_skips_subtitle'.tr(),
                      style: AppTextStyles.onboardingSubtitle,
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<FoodSkipsBloc, FoodSkipsState>(
                      builder: (context, state) {
                        return FoodSkipsOptionsList(
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
              child: AppButton(
                label: 'onboarding.continue'.tr(),
                onPressed: onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
