import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_chip_option.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/bloc/food_skips_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/food_skips_options_catalog.dart';
import 'package:flutter/material.dart';

/// Atlanan yiyecek chip listesi — onboarding + Edit Profile ortak.
final class FoodSkipsOptionsList extends StatelessWidget {
  const FoodSkipsOptionsList({
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final Set<OnboardingFoodSkip> selected;
  final ValueChanged<OnboardingFoodSkip> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: [
        for (final item in FoodSkipsOptionsCatalog.items)
          OnboardingChipOption(
            label: item.titleKey.tr(),
            imagePath: item.imagePath,
            isSelected: selected.contains(item.food),
            onTap: () => onToggle(item.food),
            selectedBorderColor: ColorName.colorOptionNegative,
          ),
      ],
    );
  }
}
