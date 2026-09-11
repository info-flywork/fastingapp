part of '../fasting_reason_view.dart';

final class FastingReasonOptions extends StatelessWidget {
  const FastingReasonOptions({
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<
      ({
        OnboardingFastingReason reason,
        String titleKey,
        String iconPath,
      })> items;
  final OnboardingFastingReason? selected;
  final ValueChanged<OnboardingFastingReason> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          OnboardingOptionCard(
            title: items[i].titleKey.tr(),
            isSelected: selected == items[i].reason,
            onTap: () => onSelected(items[i].reason),
            icon: Image.asset(
              items[i].iconPath,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ],
    );
  }
}
