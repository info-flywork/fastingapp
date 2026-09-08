part of '../diet_view.dart';

final class DietOptions extends StatelessWidget {
  const DietOptions({
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<
      ({
        OnboardingDiet diet,
        String titleKey,
        String subtitleKey,
        String imagePath,
      })> items;
  final OnboardingDiet? selected;
  final ValueChanged<OnboardingDiet> onSelected;

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
