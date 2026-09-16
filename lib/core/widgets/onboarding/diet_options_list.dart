import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_grid_option_card.dart';
import 'package:fastingapp/presentation/auth/onboard/diet/bloc/diet_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/diet/diet_options_catalog.dart';
import 'package:flutter/material.dart';

/// Diyet tipi grid listesi — onboarding + Edit Profile ortak.
final class DietOptionsList extends StatelessWidget {
  const DietOptionsList({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final OnboardingDiet? selected;
  final ValueChanged<OnboardingDiet> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = DietOptionsCatalog.items;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 189 / 142,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return OnboardingGridOptionCard(
          title: item.titleKey.tr(),
          subtitle: item.subtitleKey.tr(),
          imagePath: item.imagePath,
          isSelected: selected == item.diet,
          onTap: () => onSelected(item.diet),
        );
      },
    );
  }
}
