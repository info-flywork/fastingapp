import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_option_card.dart';
import 'package:fastingapp/presentation/auth/onboard/goal/bloc/goal_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/goal/goal_options_catalog.dart';
import 'package:flutter/material.dart';

/// Hedef seçenek listesi — onboarding + Edit Profile ortak.
final class GoalOptionsList extends StatelessWidget {
  const GoalOptionsList({
    required this.selected,
    required this.onSelected,
    this.showFooter = true,
    super.key,
  });

  final OnboardingGoal? selected;
  final ValueChanged<OnboardingGoal> onSelected;
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    final items = GoalOptionsCatalog.items;

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
            icon: Image.asset(items[i].iconPath, fit: BoxFit.contain),
          ),
        ],
        if (showFooter) ...[
          const SizedBox(height: 12),
          Text(
            'onboarding.change_anytime'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.footerHint,
          ),
        ],
      ],
    );
  }
}
