import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Onboarding ve benzeri ekranlar için paylaşılan tipografi.
///
/// Yeni soru ekranlarında bu stilleri kullan; widget içine ad-hoc TextStyle
/// yazma.
abstract final class AppTextStyles {
  /// "What do you want to achieve first?" — 28 / Semibold
  static TextStyle get onboardingTitle => const TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w600,
        fontSize: 28,
        height: 36 / 28,
        letterSpacing: -0.5,
        color: ColorName.colorTitle,
      );

  /// "We'll tailor your workouts based on this" — 18 / Medium / 60%
  static TextStyle get onboardingSubtitle => TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w500,
        fontSize: 18,
        height: 24 / 18,
        letterSpacing: -0.5,
        color: ColorName.colorSubtitle.withValues(alpha: 0.6),
      );

  /// "Lose Weight" — 18 / Semibold
  static TextStyle get optionTitle => const TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w600,
        fontSize: 18,
        height: 24 / 18,
        letterSpacing: 18 * -0.015,
        color: ColorName.colorTitle,
      );

  /// "Shed fat at a steady, kind pace" — 15 / Medium / 60%
  static TextStyle get optionSubtitle => TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w500,
        fontSize: 15,
        height: 24 / 15,
        letterSpacing: 15 * -0.015,
        color: ColorName.colorSubtitle.withValues(alpha: 0.6),
      );

  /// "Your plan is … ready" — 12 / Medium / 50%
  static TextStyle get progressLabel => TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 12 * -0.025,
        color: ColorName.colorTextPrimary.withValues(alpha: 0.5),
      );

  /// Progress içindeki yüzde vurgusu.
  static TextStyle get progressLabelEmphasis => progressLabel.copyWith(
        color: ColorName.colorTextPrimary,
        fontWeight: FontWeight.w600,
      );

  /// "You can change this anytime." — 12 / Medium / 60%
  static TextStyle get footerHint => TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 12 * -0.015,
        color: ColorName.colorSubtitle.withValues(alpha: 0.6),
      );

  /// "Most Popular" badge — 11 / Semibold / white
  static TextStyle get badgeLabel => const TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w600,
        fontSize: 11,
        height: 16 / 11,
        letterSpacing: 11 * -0.015,
        color: ColorName.colorWhite,
      );

  /// Highlight title — "Great Choice" — 32 / Semibold / white
  static TextStyle get highlightTitle => const TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w600,
        fontSize: 32,
        height: 40 / 32,
        letterSpacing: 32 * -0.015,
        color: ColorName.colorWhite,
      );

  /// Highlight subtitle — 20 / Medium / white 65%
  static TextStyle get highlightSubtitle => TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w500,
        fontSize: 20,
        height: 28 / 20,
        letterSpacing: -0.5,
        color: ColorName.colorWhite.withValues(alpha: 0.65),
      );

  /// Highlight subtitle emphasis (bold span)
  static TextStyle get highlightSubtitleEmphasis => const TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w700,
        fontSize: 20,
        height: 28 / 20,
        letterSpacing: -0.5,
        color: ColorName.colorWhite,
      );

  /// Noted summary chip — 15 / Heavy / white
  static TextStyle get notedSummaryChip => const TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w800,
        fontSize: 15,
        height: 24 / 15,
        letterSpacing: 15 * -0.015,
        color: ColorName.colorWhite,
      );

  /// Social proof metric — "1M+" — 40 / Bold / white
  static TextStyle get socialProofMetric => const TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w700,
        fontSize: 40,
        height: 48 / 40,
        letterSpacing: 40 * -0.015,
        color: ColorName.colorWhite,
      );

  /// Social proof caption — 15 / Medium / white 80%
  static TextStyle get socialProofCaption => TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w500,
        fontSize: 15,
        height: 24 / 15,
        letterSpacing: 15 * -0.015,
        color: ColorName.colorWhite.withValues(alpha: 0.8),
      );

  /// Info chip label — 15 / Semibold / white
  static TextStyle get infoChipLabel => const TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w600,
        fontSize: 15,
        height: 24 / 15,
        letterSpacing: 15 * -0.015,
        color: ColorName.colorWhite,
      );

  /// Stepper field label — "Current weight" — 15 / Medium / 60%
  static TextStyle get stepperLabel => TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w500,
        fontSize: 15,
        height: 20 / 15,
        letterSpacing: -0.5,
        color: ColorName.colorSubtitle.withValues(alpha: 0.6),
      );

  /// Stepper value — "74.0" — 24 / Semibold
  static TextStyle get stepperValue => const TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w600,
        fontSize: 24,
        height: 32 / 24,
        letterSpacing: 24 * -0.015,
        color: ColorName.colorTitle,
      );

  /// Stepper accent value (goal) — brand strong
  static TextStyle get stepperValueAccent => stepperValue.copyWith(
        color: ColorName.colorBrandStrong,
      );

  /// Stepper unit — "kg" — 15 / Medium / 60%
  static TextStyle get stepperUnit => TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w500,
        fontSize: 15,
        height: 20 / 15,
        letterSpacing: -0.5,
        color: ColorName.colorSubtitle.withValues(alpha: 0.6),
      );

  /// Journey card current weight — 15 / Heavy / white
  static TextStyle get journeyWeightCurrent => const TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w800,
        fontSize: 15,
        height: 24 / 15,
        letterSpacing: 15 * -0.015,
        color: ColorName.colorWhite,
      );

  /// Journey card goal weight — 15 / Heavy / cream
  static TextStyle get journeyWeightGoal => const TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w800,
        fontSize: 15,
        height: 24 / 15,
        letterSpacing: 15 * -0.015,
        color: ColorName.colorJourneyGoalWeight,
      );

  /// Journey footer — 12 / Medium / white 80%
  static TextStyle get journeyFooter => TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 12 * -0.015,
        color: ColorName.colorWhite.withValues(alpha: 0.8),
      );
}
