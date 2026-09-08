import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_option_card_style.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Onboarding soru seçenek kartı — ikon + başlık/alt başlık + radio.
final class OnboardingOptionCard extends StatelessWidget {
  const OnboardingOptionCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
    this.badge,
    this.style,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badge;
  final OnboardingOptionCardStyle? style;

  @override
  Widget build(BuildContext context) {
    final s = style ?? OnboardingOptionCardStyle.standard();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: s.borderRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: s.padding,
          decoration: BoxDecoration(
            color:
                isSelected ? s.selectedBackgroundColor : ColorName.colorWhite,
            borderRadius: s.borderRadius,
            border: Border.all(
              width: s.borderWidth,
              color: isSelected
                  ? s.selectedBorderColor
                  : s.unselectedBorderColor,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: s.iconSize,
                height: s.iconSize,
                child: icon,
              ),
              SizedBox(width: s.gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppTextStyles.optionTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          _MostPopularBadge(label: badge!),
                        ],
                      ],
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.optionSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: s.gap),
              _RadioIndicator(
                isSelected: isSelected,
                size: s.radioSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _MostPopularBadge extends StatelessWidget {
  const _MostPopularBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ColorName.colorOptionSelected,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label, style: AppTextStyles.badgeLabel),
    );
  }
}

final class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({
    required this.isSelected,
    required this.size,
  });

  final bool isSelected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            isSelected ? ColorName.colorOptionSelected : ColorName.colorWhite,
        border: Border.all(
          width: 2,
          color: isSelected
              ? ColorName.colorOptionSelected
              : ColorName.colorRadioBorder,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 14, color: ColorName.colorWhite)
          : null,
    );
  }
}
