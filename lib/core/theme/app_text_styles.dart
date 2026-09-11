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
  static TextStyle get stepperValueAccent =>
      stepperValue.copyWith(color: ColorName.colorBrandStrong);

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

  /// Target date value — "Aug 20, 2026" — 16 / Semibold
  static TextStyle get targetDateValue => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 16 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Fasting plan title — "16:8" — 26 / Heavy
  static TextStyle get planOptionTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w800,
    fontSize: 26,
    height: 36 / 26,
    letterSpacing: 26 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Fasting plan badge — "POPULAR" — 11 / Semibold / white / +2%
  static TextStyle get planBadgeLabel => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 11,
    height: 16 / 11,
    letterSpacing: 11 * 0.02,
    color: ColorName.colorWhite,
  );

  /// Time picker label — "I start at:" — 18 / Medium
  static TextStyle get timePickerLabel => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Time picker selected value — "07" — 32 / Semibold
  static TextStyle get timePickerValue => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 32,
    height: 40 / 32,
    letterSpacing: 32 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Time picker unselected value — faded
  static TextStyle get timePickerValueFaded => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 32,
    height: 40 / 32,
    letterSpacing: 32 * -0.015,
    color: ColorName.colorTitle.withValues(alpha: 0.2),
  );

  /// Building plan title — "Building your plan..." — 32 / Semibold
  static TextStyle get buildingPlanTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 32,
    height: 40 / 32,
    letterSpacing: 32 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Building plan section title — "Body data" — 20 / Bold
  static TextStyle get buildingPlanSectionTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 28 / 20,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Building plan chip — "Woman" — 18 / Semibold
  static TextStyle get buildingPlanChip => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: 18 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Weight projection eyebrow — "YOU COULD REACH" — 20 / Semibold / white 80%
  static TextStyle get weightProjectionEyebrow => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 28 / 20,
    letterSpacing: 20 * 0.04,
    color: ColorName.colorWhite.withValues(alpha: 0.8),
  );

  /// Weight projection hero — "68 kg" — 64 / Heavy
  static TextStyle get weightProjectionHero => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w800,
    fontSize: 64,
    height: 56 / 64,
    letterSpacing: 64 * -0.015,
    color: ColorName.colorWhite,
  );

  /// Weight projection date — "by August 30" — 20 / Medium / white 85%
  static TextStyle get weightProjectionDate => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 20,
    height: 28 / 20,
    letterSpacing: -0.5,
    color: ColorName.colorWhite.withValues(alpha: 0.85),
  );

  /// Weight projection axis value — "74.0" — 28 / Heavy
  static TextStyle get weightProjectionTodayValue => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w800,
    fontSize: 28,
    height: 36 / 28,
    letterSpacing: 28 * -0.015,
    color: ColorName.colorWhite,
  );

  /// Weight projection goal value — "68.0" — 28 / Heavy / cream
  static TextStyle get weightProjectionGoalValue => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w800,
    fontSize: 28,
    height: 36 / 28,
    letterSpacing: 28 * -0.015,
    color: ColorName.colorJourneyGoalWeight,
  );

  /// Weight projection axis label — "TODAY" / "GOAL" — 12 / Semibold
  static TextStyle get weightProjectionAxisLabel => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 12 * 0.06,
    color: ColorName.colorWhite.withValues(alpha: 0.75),
  );

  /// Weight projection body — 20 / Medium / white 65%
  static TextStyle get weightProjectionBody => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 20,
    height: 28 / 20,
    letterSpacing: -0.5,
    color: ColorName.colorWhite.withValues(alpha: 0.65),
  );

  /// Good company title — 48 / Semibold
  static TextStyle get goodCompanyTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 48,
    height: 48 / 48,
    letterSpacing: 48 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Good company stat value — 26 / Heavy
  static TextStyle get goodCompanyStatValue => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w800,
    fontSize: 26,
    height: 36 / 26,
    letterSpacing: 26 * -0.015,
  );

  /// Good company stat label — 15 / Medium / subtitle 60%
  static TextStyle get goodCompanyStatLabel => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    height: 24 / 15,
    letterSpacing: 15 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Good company reviewer name — 20 / Semibold
  static TextStyle get goodCompanyReviewer => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 28 / 20,
    letterSpacing: 20 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Good company quote — 18 / Medium / subtitle 60%
  static TextStyle get goodCompanyQuote => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: -0.5,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Home "Get Premium" — 16 / Semibold / white (Figma SF Pro 590).
  /// Upright Semibold yok; w600 → Bold OTF (projede semibold standardı).
  static TextStyle get homePremium => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 16 * -0.015,
    color: ColorName.colorWhite,
    shadows: [
      Shadow(
        color: ColorName.colorBlack.withValues(alpha: 0.05),
        offset: const Offset(0, 1),
        blurRadius: 4,
      ),
    ],
  );

  /// Home streak count — 16 / Heavy
  static TextStyle get homeStreakCount => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w800,
    fontSize: 16,
    height: 20 / 16,
    letterSpacing: -0.5,
  );

  /// Home week day label — "MON" — 9 / Medium
  static TextStyle get homeWeekDay => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 9,
    height: 14 / 9,
    letterSpacing: 9 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.5),
  );

  /// Home week date — "22" — 16 / Semibold
  static TextStyle get homeWeekDate => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 16 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Home week hours pill — "10h" — 11 / Semibold / white
  static TextStyle get homeWeekHours => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 11,
    height: 16 / 11,
    letterSpacing: 11 * -0.015,
    color: ColorName.colorWhite,
  );

  /// Home card section title — 16 / Semibold
  static TextStyle get homeCardTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Home flip clock digits — Share Tech 51.8 / Regular / −8.5%
  static TextStyle get homeFlipDigits => const TextStyle(
    fontFamily: FontFamily.shareTech,
    fontWeight: FontWeight.w400,
    fontSize: 51.8,
    height: 1,
    letterSpacing: 51.8 * -0.085,
    color: ColorName.colorTitle,
  );

  /// Home flip clock unit — 12 / Medium / 50%
  static TextStyle get homeFlipUnit => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 12 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.5),
  );

  /// Home challenge eyebrow — 14 / Medium / 50%
  static TextStyle get homeChallengeEyebrow => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 14 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.5),
  );

  /// Home challenge title — 18 / Semibold
  static TextStyle get homeChallengeTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Home challenge subtitle — 14 / Semibold / 60%
  static TextStyle get homeChallengeSubtitle => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 14 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Home "already in" — 12 / Semibold
  static TextStyle get homeAlreadyIn => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Home Join Now — 14 / Semibold / white
  static TextStyle get homeJoinNow => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 14 * -0.02,
    color: ColorName.colorWhite,
  );

  /// Home metric label — 16 / Semibold
  static TextStyle get homeMetricLabel => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Home metric current value — 16 / Heavy
  static TextStyle get homeMetricValue => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w800,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 0.5,
    color: ColorName.colorTextPrimary,
  );

  /// Home metric goal — 16 / Semibold / 60%
  static TextStyle get homeMetricGoal => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 16 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Bottom nav label — 11 / Semibold
  static TextStyle get navLabel => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 11,
    height: 14 / 11,
    letterSpacing: 11 * -0.015,
    color: ColorName.colorTextPrimary,
  );

  /// Login brand — Baloo 52 / Regular / −1.5%
  static TextStyle get loginBrand => const TextStyle(
    fontFamily: FontFamily.baloo,
    fontWeight: FontWeight.w400,
    fontSize: 52,
    height: 1,
    letterSpacing: 52 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Login WELCOME — 28 / Semibold
  static TextStyle get loginWelcome => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    height: 34 / 28,
    letterSpacing: 28 * -0.02,
    color: ColorName.colorTitle,
  );

  /// Login slogan — 16 / Medium / 35%
  static TextStyle get loginSlogan => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 16 * -0.02,
    color: ColorName.colorTitle.withValues(alpha: 0.35),
  );

  /// Login "or" — 14 / Medium / 50%
  static TextStyle get loginOr => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 18 / 14,
    color: ColorName.colorTitle.withValues(alpha: 0.5),
  );

  /// Login guest — 14 / Medium / 65%
  static TextStyle get loginGuest => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 18 / 14,
    color: ColorName.colorTitle.withValues(alpha: 0.65),
  );

  /// Login legal body — 12 / Regular / 65%
  static TextStyle get loginLegal => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 18 / 12,
    color: ColorName.colorTitle.withValues(alpha: 0.65),
  );

  /// Login legal link — 12 / Medium / underline / 65%
  static TextStyle get loginLegalLink => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 18 / 12,
    color: ColorName.colorTitle.withValues(alpha: 0.65),
    decoration: TextDecoration.underline,
    decorationColor: ColorName.colorTitle.withValues(alpha: 0.65),
  );
}
