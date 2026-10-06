part of '../weight_history_view.dart';

final class WeightHistoryOptions extends StatelessWidget {
  const WeightHistoryOptions({
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<
    ({
      OnboardingWeightHistory history,
      String titleKey,
      String subtitleKey,
      String iconPath,
    })
  >
  items;
  final OnboardingWeightHistory? selected;
  final ValueChanged<OnboardingWeightHistory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          OnboardingOptionCard(
            title: items[i].titleKey.tr(),
            subtitle: items[i].subtitleKey.tr(),
            isSelected: selected == items[i].history,
            onTap: () => onSelected(items[i].history),
            icon: appImage(items[i].iconPath, fit: BoxFit.contain),
          ),
        ],
      ],
    );
  }
}
