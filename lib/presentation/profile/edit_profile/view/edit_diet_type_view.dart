import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/widgets/onboarding/diet_options_list.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/diet/bloc/diet_bloc.dart';
import 'package:fastingapp/presentation/profile/view/widgets/edit_profile_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Diyet tipi seçimi — tam ekran.
final class EditDietTypeView extends StatefulWidget {
  const EditDietTypeView({this.initial, super.key});

  final OnboardingDiet? initial;

  @override
  State<EditDietTypeView> createState() => _EditDietTypeViewState();
}

class _EditDietTypeViewState extends State<EditDietTypeView> {
  late OnboardingDiet? _selected = widget.initial;

  void _onSelected(OnboardingDiet diet) {
    setState(() => _selected = diet);
    context.pop(diet);
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
                title: 'profile.diet_type'.tr(),
                onBack: () => context.pop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: DietOptionsList(
                  selected: _selected,
                  onSelected: _onSelected,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
