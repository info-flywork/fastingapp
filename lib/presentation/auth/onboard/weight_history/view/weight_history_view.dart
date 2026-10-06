import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_option_card.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_progress_header.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/weight_history/bloc/weight_history_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'mixin/weight_history_view_mixin.dart';
part 'widgets/weight_history_options.dart';

/// Onboarding: daha önce kilo vermeyi denedi mi?
final class WeightHistoryView extends StatefulWidget {
  const WeightHistoryView({super.key});

  @override
  State<WeightHistoryView> createState() => _WeightHistoryViewState();
}

class _WeightHistoryViewState extends State<WeightHistoryView>
    with WeightHistoryViewMixin {
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
                fromProgress: 0.60,
                targetProgress: 0.70,
                onBack: onBack,
              ),
              const SizedBox(height: 40),
              Text(
                'onboarding.weight_history_title'.tr(),
                style: AppTextStyles.onboardingTitle,
              ),
              const SizedBox(height: 8),
              Text(
                'onboarding.weight_history_subtitle'.tr(),
                style: AppTextStyles.onboardingSubtitle,
              ),
              const SizedBox(height: 24),
              BlocBuilder<WeightHistoryBloc, WeightHistoryState>(
                builder: (context, state) {
                  return WeightHistoryOptions(
                    items: weightHistoryOptions,
                    selected: state.selected,
                    onSelected: onHistorySelected,
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
