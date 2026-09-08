part of '../about_you_view.dart';

final class AboutYouOptions extends StatelessWidget {
  const AboutYouOptions({
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<({OnboardingGender gender, String titleKey, String iconPath})>
      items;
  final OnboardingGender? selected;
  final ValueChanged<OnboardingGender> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          OnboardingOptionCard(
            title: items[i].titleKey.tr(),
            isSelected: selected == items[i].gender,
            onTap: () => onSelected(items[i].gender),
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
