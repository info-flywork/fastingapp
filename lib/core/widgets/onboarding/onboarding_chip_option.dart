import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Onboarding çoklu seçim chip’i (ikon + etiket).
final class OnboardingChipOption extends StatelessWidget {
  const OnboardingChipOption({
    required this.label,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
    this.iconSize = 40,
    this.selectedBorderColor,
    super.key,
  });

  final String label;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;
  final double iconSize;

  /// null → [ColorName.colorOptionSelected]
  final Color? selectedBorderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
          decoration: BoxDecoration(
            color: ColorName.colorWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: 2,
              color: isSelected
                  ? (selectedBorderColor ?? ColorName.colorOptionSelected)
                  : ColorName.colorBlack.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              appImage(
                imagePath,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 3),
              Text(label, style: AppTextStyles.optionTitle, maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }
}
