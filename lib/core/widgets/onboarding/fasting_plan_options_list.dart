import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_plan_option_card.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/bloc/fasting_plan_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/fasting_plan_options_catalog.dart';
import 'package:flutter/material.dart';

/// Oruç planı grid listesi — onboarding + Edit Profile ortak.
final class FastingPlanOptionsList extends StatelessWidget {
  const FastingPlanOptionsList({
    required this.selected,
    required this.onSelected,
    this.showFooter = true,
    super.key,
  });

  final OnboardingFastingPlan? selected;
  final ValueChanged<OnboardingFastingPlan> onSelected;
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    final items = FastingPlanOptionsCatalog.items;

    return Column(
      children: [
        GridView.builder(
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
        ),
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
