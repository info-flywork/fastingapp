import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_stepper_field.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/profile/view/widgets/edit_profile_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Boy / yaş düzenleme sonucu.
final class HeightEditResult {
  const HeightEditResult({required this.heightCm, required this.age});

  final int heightCm;
  final int age;
}

/// Boy ve yaş düzenleme — tam ekran.
final class EditHeightView extends StatefulWidget {
  const EditHeightView({
    this.initialHeightCm = 173,
    this.initialAge = 29,
    super.key,
  });

  final int initialHeightCm;
  final int initialAge;

  @override
  State<EditHeightView> createState() => _EditHeightViewState();
}

class _EditHeightViewState extends State<EditHeightView> {
  late int _heightCm = widget.initialHeightCm.clamp(100, 250);
  late int _age = widget.initialAge.clamp(13, 100);

  void _onBack() {
    context.pop(
      HeightEditResult(heightCm: _heightCm, age: _age),
    );
  }

  void _onHeightDelta(int delta) {
    setState(() => _heightCm = (_heightCm + delta).clamp(100, 250));
  }

  void _onAgeDelta(int delta) {
    setState(() => _age = (_age + delta).clamp(13, 100));
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
                title: 'onboarding.height'.tr(),
                onBack: _onBack,
              ),
            ),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                children: [
                  OnboardingStepperField(
                    label: 'onboarding.height'.tr(),
                    displayValue: '$_heightCm',
                    unit: 'onboarding.unit_cm'.tr(),
                    onDecrement: () => _onHeightDelta(-1),
                    onIncrement: () => _onHeightDelta(1),
                  ),
                  const SizedBox(height: 12),
                  OnboardingStepperField(
                    label: 'onboarding.age'.tr(),
                    displayValue: '$_age',
                    onDecrement: () => _onAgeDelta(-1),
                    onIncrement: () => _onAgeDelta(1),
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
