import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/widgets/onboarding/gender_options_list.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/about_you/bloc/about_you_bloc.dart';
import 'package:fastingapp/presentation/profile/view/widgets/edit_profile_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Cinsiyet seçimi — tam ekran.
final class EditGenderView extends StatefulWidget {
  const EditGenderView({this.initial, super.key});

  final OnboardingGender? initial;

  @override
  State<EditGenderView> createState() => _EditGenderViewState();
}

class _EditGenderViewState extends State<EditGenderView> {
  late OnboardingGender? _selected = widget.initial;

  void _onSelected(OnboardingGender gender) {
    setState(() => _selected = gender);
    context.pop(gender);
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
                title: 'profile.gender'.tr(),
                onBack: () => context.pop(),
              ),
            ),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                children: [
                  GenderOptionsList(
                    selected: _selected,
                    onSelected: _onSelected,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
