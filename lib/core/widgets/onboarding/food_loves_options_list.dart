import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_chip_option.dart';
import 'package:fastingapp/presentation/auth/onboard/food_loves/bloc/food_loves_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/food_loves/food_loves_options_catalog.dart';
import 'package:flutter/material.dart';

/// Tercih edilen yiyecek chip listesi — onboarding + Edit Profile ortak.
final class FoodLovesOptionsList extends StatelessWidget {
  const FoodLovesOptionsList({
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final Set<OnboardingFoodLove> selected;
  final ValueChanged<OnboardingFoodLove> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: [
        for (final item in FoodLovesOptionsCatalog.items)
          OnboardingChipOption(
            label: item.titleKey.tr(),
            imagePath: item.imagePath,
            isSelected: selected.contains(item.food),
            onTap: () => onToggle(item.food),
          ),
      ],
    );
  }
}
