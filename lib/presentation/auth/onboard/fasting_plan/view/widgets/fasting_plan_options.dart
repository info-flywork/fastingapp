part of '../fasting_plan_view.dart';

final class FastingPlanOptions extends StatelessWidget {
  const FastingPlanOptions({
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<
    ({
      OnboardingFastingPlan plan,
      String titleKey,
      String subtitleKey,
      String badgeKey,
      Color badgeColor,
    })
  >
  items;
  final OnboardingFastingPlan? selected;
  final ValueChanged<OnboardingFastingPlan> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 189 / 125,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return OnboardingPlanOptionCard(
          title: item.titleKey.tr(),
          subtitle: item.subtitleKey.tr(),
          badgeLabel: item.badgeKey.tr(),
          badgeColor: item.badgeColor,
          isSelected: selected == item.plan,
          onTap: () => onSelected(item.plan),
        );
      },
    );
  }
}
