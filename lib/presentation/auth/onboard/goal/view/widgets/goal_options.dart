part of '../goal_view.dart';

final class GoalOptions extends StatelessWidget {
  const GoalOptions({
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<
      ({
        OnboardingGoal goal,
        String titleKey,
        String subtitleKey,
        String iconPath,
        String? badgeKey,
      })> items;
  final OnboardingGoal? selected;
  final ValueChanged<OnboardingGoal> onSelected;

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
            badge: items[i].badgeKey?.tr(),
            isSelected: selected == items[i].goal,
            onTap: () => onSelected(items[i].goal),
            icon: Image.asset(
              items[i].iconPath,
              fit: BoxFit.contain,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'onboarding.change_anytime'.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.footerHint,
        ),
      ],
    );
  }
}
