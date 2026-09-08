part of '../food_loves_view.dart';

final class FoodLovesOptions extends StatelessWidget {
  const FoodLovesOptions({
    required this.items,
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final List<({OnboardingFoodLove food, String titleKey, String imagePath})>
      items;
  final Set<OnboardingFoodLove> selected;
  final ValueChanged<OnboardingFoodLove> onToggle;

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
          ),
      ],
    );
  }
}
