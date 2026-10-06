part of '../obstacles_view.dart';

final class ObstaclesOptions extends StatelessWidget {
  const ObstaclesOptions({
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<({OnboardingObstacle obstacle, String titleKey, String iconPath})>
  items;
  final OnboardingObstacle? selected;
  final ValueChanged<OnboardingObstacle> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          OnboardingOptionCard(
            title: items[i].titleKey.tr(),
            isSelected: selected == items[i].obstacle,
            onTap: () => onSelected(items[i].obstacle),
            icon: appImage(items[i].iconPath, fit: BoxFit.contain),
          ),
        ],
      ],
    );
  }
}
