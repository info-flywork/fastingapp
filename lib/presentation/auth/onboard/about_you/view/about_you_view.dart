import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/onboarding/gender_options_list.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_progress_header.dart';
import 'package:fastingapp/domain/onboarding/onboarding_draft.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/about_you/bloc/about_you_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'mixin/about_you_view_mixin.dart';

/// Onboarding: cinsiyet / hakkında bilgi.
final class AboutYouView extends StatefulWidget {
  const AboutYouView({super.key});

  @override
  State<AboutYouView> createState() => _AboutYouViewState();
}

class _AboutYouViewState extends State<AboutYouView> with AboutYouViewMixin {
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
              OnboardingProgressHeader(
                fromProgress: 0.10,
                targetProgress: 0.20,
                onBack: onBack,
              ),
              const SizedBox(height: 40),
              Text(
                'onboarding.about_you_title'.tr(),
                style: AppTextStyles.onboardingTitle,
              ),
              const SizedBox(height: 8),
              Text(
                'onboarding.about_you_subtitle'.tr(),
                style: AppTextStyles.onboardingSubtitle,
              ),
              const SizedBox(height: 24),
              BlocBuilder<AboutYouBloc, AboutYouState>(
                builder: (context, state) {
                  return GenderOptionsList(
                    selected: state.selected,
                    onSelected: onGenderSelected,
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
