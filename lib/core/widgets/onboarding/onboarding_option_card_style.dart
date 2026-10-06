import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Onboarding seçenek kartı (seçili / seçili değil) dekorasyonu.
@immutable
final class OnboardingOptionCardStyle {
  const OnboardingOptionCardStyle({
    required this.borderRadius,
    required this.padding,
    required this.gap,
    required this.borderWidth,
    required this.unselectedBorderColor,
    required this.selectedBorderColor,
    required this.selectedBackgroundColor,
    required this.iconSize,
    required this.radioSize,
  });

  factory OnboardingOptionCardStyle.standard() {
    return OnboardingOptionCardStyle(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(12),
      gap: 10,
      borderWidth: 2,
      unselectedBorderColor: ColorName.colorBlack.withValues(alpha: 0.05),
      selectedBorderColor: ColorName.colorOptionSelected,
      selectedBackgroundColor: ColorName.colorOptionSelected.withValues(
        alpha: 0.08,
      ),
      iconSize: 54,
      radioSize: 24,
    );
  }

  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final double gap;
  final double borderWidth;
  final Color unselectedBorderColor;
  final Color selectedBorderColor;
  final Color selectedBackgroundColor;
  final double iconSize;
  final double radioSize;
}
