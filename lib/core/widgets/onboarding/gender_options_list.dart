import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_option_card.dart';
import 'package:fastingapp/presentation/auth/onboard/about_you/bloc/about_you_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/about_you/gender_options_catalog.dart';
import 'package:flutter/material.dart';

/// Cinsiyet seçenek listesi — onboarding + Edit Profile ortak.
final class GenderOptionsList extends StatelessWidget {
  const GenderOptionsList({
    required this.selected,
    required this.onSelected,
    this.showFooter = true,
    super.key,
  });

  final OnboardingGender? selected;
  final ValueChanged<OnboardingGender> onSelected;
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    final items = GenderOptionsCatalog.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          OnboardingOptionCard(
            title: items[i].titleKey.tr(),
            isSelected: selected == items[i].gender,
            onTap: () => onSelected(items[i].gender),
            icon: appImage(items[i].iconPath, fit: BoxFit.contain),
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
