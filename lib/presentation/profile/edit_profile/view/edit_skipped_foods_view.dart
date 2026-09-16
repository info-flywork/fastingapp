import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/onboarding/food_skips_options_list.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/bloc/food_skips_bloc.dart';
import 'package:fastingapp/presentation/profile/view/widgets/edit_profile_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Atlanan yiyecekler — tam ekran (çoklu seçim).
final class EditSkippedFoodsView extends StatefulWidget {
  const EditSkippedFoodsView({this.initial = const {}, super.key});

  final Set<OnboardingFoodSkip> initial;

  @override
  State<EditSkippedFoodsView> createState() => _EditSkippedFoodsViewState();
}

class _EditSkippedFoodsViewState extends State<EditSkippedFoodsView> {
  late final Set<OnboardingFoodSkip> _selected = Set.of(widget.initial);

  void _onToggle(OnboardingFoodSkip food) {
    setState(() {
      if (_selected.contains(food)) {
        _selected.remove(food);
      } else {
        _selected.add(food);
      }
    });
  }

  void _onSave() => context.pop(Set<OnboardingFoodSkip>.of(_selected));

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
                title: 'profile.skipped_foods'.tr(),
                onBack: () => context.pop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    FoodSkipsOptionsList(
                      selected: _selected,
                      onToggle: _onToggle,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: AppButton(
                label: 'profile.save'.tr(),
                onPressed: _onSave,
                showIcon: false,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
