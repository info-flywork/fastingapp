import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:fastingapp/core/utils/extensions/future_extensions.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/onboarding/building_plan_section.dart';
import 'package:fastingapp/data/model/onboarding/onboarding_result.dart';
import 'package:fastingapp/domain/onboarding/onboarding_draft.dart';
import 'package:fastingapp/domain/onboarding/onboarding_repository.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_event.dart';
import 'package:fastingapp/presentation/auth/onboard/about_you/gender_options_catalog.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/fasting_plan_options_catalog.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_reason/bloc/fasting_reason_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/food_loves/food_loves_options_catalog.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/food_skips_options_catalog.dart';
import 'package:fastingapp/presentation/auth/onboard/weight_history/bloc/weight_history_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'mixin/building_plan_view_mixin.dart';

/// Onboarding sonu: plan oluşturuluyor animasyonu.
final class BuildingPlanView extends StatefulWidget {
  const BuildingPlanView({super.key});

  @override
  State<BuildingPlanView> createState() => _BuildingPlanViewState();
}

class _BuildingPlanViewState extends State<BuildingPlanView>
    with BuildingPlanViewMixin, TickerProviderStateMixin {
  late final AnimationController _bodyController;
  late final AnimationController _lifestyleController;
  late final Animation<double> _bodyProgress;
  late final Animation<double> _lifestyleProgress;

  bool _bodyComplete = false;
  bool _lifestyleStarted = false;
  bool _lifestyleComplete = false;
  bool _showContinue = false;

  @override
  void initState() {
    super.initState();
    _bodyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _lifestyleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _bodyProgress = CurvedAnimation(
      parent: _bodyController,
      curve: Curves.easeInOutCubic,
    );
    _lifestyleProgress = CurvedAnimation(
      parent: _lifestyleController,
      curve: Curves.easeInOutCubic,
    );
    startSubmission();
    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await _bodyController.forward();
    if (!mounted) return;
    setState(() => _bodyComplete = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() => _lifestyleStarted = true);
    await _lifestyleController.forward();
    if (!mounted) return;
    setState(() => _lifestyleComplete = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _showContinue = true);
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _lifestyleController.dispose();
    super.dispose();
  }

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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    appImage(AppImages.building.path, fit: BoxFit.contain),
                    Text(
                      'onboarding.building_plan_title'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.buildingPlanTitle,
                    ),
                    const SizedBox(height: 32),
                    AnimatedBuilder(
                      animation: _bodyProgress,
                      builder: (context, _) {
                        return BuildingPlanSection(
                          title: 'onboarding.building_body_data'.tr(),
                          progress: _bodyProgress.value,
                          chips: bodyChips,
                          isComplete: _bodyComplete,
                          showChips: !_bodyComplete,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: ColorName.colorBlack.withValues(alpha: 0.05),
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _lifestyleProgress,
                      builder: (context, _) {
                        return BuildingPlanSection(
                          title: 'onboarding.building_lifestyle'.tr(),
                          progress: _lifestyleStarted
                              ? _lifestyleProgress.value
                              : 0,
                          chips: lifestyleChips,
                          isComplete: _lifestyleComplete,
                          showChips: _lifestyleStarted && !_lifestyleComplete,
                          showProgressBar: _lifestyleStarted,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              child: _showContinue
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: AppButton(
                        label: 'onboarding.continue'.tr(),
                        onPressed: onContinue,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
