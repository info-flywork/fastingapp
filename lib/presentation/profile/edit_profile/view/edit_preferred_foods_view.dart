import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/onboarding/food_loves_options_list.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/food_loves/bloc/food_loves_bloc.dart';
import 'package:fastingapp/presentation/profile/view/widgets/edit_profile_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Tercih edilen yiyecekler — tam ekran (çoklu seçim).
final class EditPreferredFoodsView extends StatefulWidget {
  const EditPreferredFoodsView({this.initial = const {}, super.key});

  final Set<OnboardingFoodLove> initial;

  @override
  State<EditPreferredFoodsView> createState() => _EditPreferredFoodsViewState();
}

class _EditPreferredFoodsViewState extends State<EditPreferredFoodsView> {
  late final Set<OnboardingFoodLove> _selected = Set.of(widget.initial);

  void _onToggle(OnboardingFoodLove food) {
    setState(() {
      if (_selected.contains(food)) {
        _selected.remove(food);
      } else {
        _selected.add(food);
      }
    });
  }

  void _onSave() => context.pop(Set<OnboardingFoodLove>.of(_selected));

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
                title: 'profile.preferred_foods'.tr(),
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
                      'onboarding.food_loves_title'.tr(),
                      style: AppTextStyles.onboardingTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'onboarding.food_loves_subtitle'.tr(),
                      style: AppTextStyles.onboardingSubtitle,
                    ),
                    const SizedBox(height: 24),
                    FoodLovesOptionsList(
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
