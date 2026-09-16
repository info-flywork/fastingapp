import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/widgets/onboarding/goal_options_list.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/goal/bloc/goal_bloc.dart';
import 'package:fastingapp/presentation/profile/view/widgets/edit_profile_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Oruç hedefi seçimi — tam ekran.
final class EditFastingTargetView extends StatefulWidget {
  const EditFastingTargetView({this.initial, super.key});

  final OnboardingGoal? initial;

  @override
  State<EditFastingTargetView> createState() => _EditFastingTargetViewState();
}

class _EditFastingTargetViewState extends State<EditFastingTargetView> {
  late OnboardingGoal? _selected = widget.initial;

  void _onSelected(OnboardingGoal goal) {
    setState(() => _selected = goal);
    context.pop(goal);
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
                title: 'profile.fasting_target'.tr(),
                onBack: () => context.pop(),
              ),
            ),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                children: [
                  GoalOptionsList(selected: _selected, onSelected: _onSelected),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
