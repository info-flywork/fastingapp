part of '../food_skips_view.dart';

final class FoodSkipsOptions extends StatelessWidget {
  const FoodSkipsOptions({
    required this.items,
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final List<({OnboardingFoodSkip food, String titleKey, String imagePath})>
      items;
  final Set<OnboardingFoodSkip> selected;
  final ValueChanged<OnboardingFoodSkip> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: [
        for (final item in items)
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
