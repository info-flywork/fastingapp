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
import 'package:fastingapp/presentation/auth/onboard/fasting_reason/bloc/fasting_reason_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'mixin/fasting_reason_view_mixin.dart';
part 'widgets/fasting_reason_options.dart';
part 'widgets/fasting_reason_target_date.dart';

/// Onboarding: ne için oruç tutuyorsun?
final class FastingReasonView extends StatefulWidget {
  const FastingReasonView({super.key});

  @override
  State<FastingReasonView> createState() => _FastingReasonViewState();
}

class _FastingReasonViewState extends State<FastingReasonView>
    with FastingReasonViewMixin {
  static const _buttonAnimDuration = Duration(milliseconds: 350);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorName.colorWhite,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingProgressHeader(
                fromProgress: 0.80,
                targetProgress: 0.90,
                onBack: onBack,
              ),
              const SizedBox(height: 40),
              Text(
                'onboarding.fasting_reason_title'.tr(),
                style: AppTextStyles.onboardingTitle,
              ),
              const SizedBox(height: 8),
              Text(
                'onboarding.fasting_reason_subtitle'.tr(),
                style: AppTextStyles.onboardingSubtitle,
              ),
              const SizedBox(height: 24),
              BlocBuilder<FastingReasonBloc, FastingReasonState>(
                builder: (context, state) {
                  return FastingReasonOptions(
                    items: reasonOptions,
                    selected: state.selected,
                    onSelected: onReasonSelected,
                  );
                },
              ),
              BlocBuilder<FastingReasonBloc, FastingReasonState>(
                buildWhen: (prev, next) =>
                    prev.targetDate != next.targetDate ||
                    prev.selected != next.selected,
                builder: (context, state) {
                  if (state.targetDate == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: FastingReasonTargetDate(
                      dateLabel: formatTargetDate(state.targetDate!),
                    ),
                  );
                },
              ),
              BlocBuilder<FastingReasonBloc, FastingReasonState>(
                buildWhen: (prev, next) => prev.selected != next.selected,
                builder: (context, state) {
                  final visible = state.selected != null;
                  return AnimatedSize(
                    duration: _buttonAnimDuration,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: visible
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: _buttonAnimDuration,
                              curve: Curves.easeOutCubic,
                              builder: (context, t, child) {
                                return Opacity(
                                  opacity: t,
                                  child: Transform.translate(
                                    offset: Offset(0, 16 * (1 - t)),
                                    child: child,
                                  ),
                                );
                              },
                              child: AppButton(
                                label: 'onboarding.continue'.tr(),
                                onPressed: onContinue,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
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
