import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/widgets/onboarding/fasting_plan_options_list.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/bloc/fasting_plan_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/fasting_plan_options_catalog.dart';
import 'package:fastingapp/presentation/profile/view/widgets/edit_profile_app_bar.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/presentation/profile/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Oruç planı seçimi — tam ekran.
final class EditFastingPlanView extends StatefulWidget {
  const EditFastingPlanView({this.initial, super.key});

  final OnboardingFastingPlan? initial;

  @override
  State<EditFastingPlanView> createState() => _EditFastingPlanViewState();
}

class _EditFastingPlanViewState extends State<EditFastingPlanView> {
  late OnboardingFastingPlan? _selected = widget.initial;

  Future<void> _onSelected(OnboardingFastingPlan plan) async {
    if (!await FastingPlanOptionsCatalog.ensureUnlocked(plan) || !mounted) {
      return;
    }
    setState(() => _selected = plan);
    context.pop(plan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorName.colorWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: EditProfileAppBar(
                title: 'profile.fasting_plan'.tr(),
                onBack: () => context.pop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: FastingPlanOptionsList(
                  selected: _selected,
                  onSelected: _onSelected,
                  age: getIt<ProfileBloc>().state.profile.age,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
