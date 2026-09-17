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

  /// Home challenge eyebrow — 18 / Semibold / #09090B
  static TextStyle get homeChallengeEyebrow => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
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

  /// Home challenge subtitle — 14 / Semibold / #3C3C43 @ 60%
  static TextStyle get homeChallengeSubtitle => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 14 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Home "already in" count — 12 / Semibold / #09090B
  static TextStyle get homeAlreadyInCount => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Home "already in" label — 12 / Semibold / #3C3C4399
  static TextStyle get homeAlreadyIn => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: -0.5,
    color: Color(0x993C3C43),
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

  /// Home weight records title — 18 / Semibold
  static TextStyle get homeWeightTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Home weight current value — 28 / Semibold
  static TextStyle get homeWeightValue => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 28,
    height: 36 / 28,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Home weight unit "kg" — 14 / Semibold / #3C3C4399
  static TextStyle get homeWeightUnit => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 14 * -0.015,
    color: Color(0x993C3C43),
  );

  /// Home weight Start/Target label — 14 / Semibold / #3C3C4399
  static TextStyle get homeWeightBoundLabel => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 14 * -0.015,
    color: Color(0x993C3C43),
  );

  /// Home weight Start/Target value — 14 / Semibold
  static TextStyle get homeWeightBoundValue => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 14 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Metabolic Twin title — 18 / Semibold (homeWeightTitle ile aynı)
  static TextStyle get homeMetabolicTitle => homeWeightTitle;

  /// Metabolic feeling — 16 / Semibold
  static TextStyle get homeMetabolicFeeling => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Metabolic subtitle — 14 / Semibold / #3C3C4399
  static TextStyle get homeMetabolicSubtitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 14 * -0.015,
    color: Color(0x993C3C43),
  );

  /// Metabolic gauge percent — 24 / Semibold
  static TextStyle get homeMetabolicGaugeValue => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 28 / 24,
    letterSpacing: -0.67,
    color: ColorName.colorTitle,
  );

  /// Metabolic gauge label — 15 / Medium / #3C3C4399
  static TextStyle get homeMetabolicGaugeLabel => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    height: 20 / 15,
    letterSpacing: -0.67,
    color: Color(0x993C3C43),
  );

  /// Meal Records title — 18 / Semibold
  static TextStyle get homeMealRecordsTitle => homeWeightTitle;

  /// Meal timestamp — 14 / Semibold / #3C3C4399
  static TextStyle get homeMealTimestamp => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 14 * -0.015,
    color: Color(0x993C3C43),
  );

  /// Meal tag pill — 14 / Semibold
  static TextStyle get homeMealTag => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 24 / 14,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Hunger Tracker title — 18 / Semibold
  static TextStyle get homeHungerTitle => homeWeightTitle;

  /// Hunger question — 16 / Semibold
  static TextStyle get homeHungerQuestion => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Hunger subtitle — 14 / Semibold / #3C3C4399
  static TextStyle get homeHungerSubtitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 14 * -0.015,
    color: Color(0x993C3C43),
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

  /// Water page date — 18 / Semibold
  static TextStyle get waterToday => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Water hero amount — 80 / Semibold
  static TextStyle get waterHeroAmount => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 80,
    height: 88 / 80,
    letterSpacing: -1.34,
    color: ColorName.colorTitle,
  );

  /// Water unit — 40 / Semibold
  static TextStyle get waterUnit => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 40,
    height: 64 / 40,
    letterSpacing: -1.34,
    color: ColorName.colorTitle,
  );

  /// Water goal achieved — 18 / Semibold / blue
  static TextStyle get waterGoalAchieved => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: -0.5,
    color: ColorName.colorWaterAction,
  );

  /// Water daily target — 16 / Semibold
  static TextStyle get waterDailyTarget => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16.07,
    height: 21.42 / 16.07,
    letterSpacing: 16.07 * -0.015,
    color: ColorName.colorSubtitle,
  );

  static TextStyle get waterDailyTargetBold => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 16.07,
    height: 21.42 / 16.07,
    letterSpacing: 16.07 * -0.015,
    color: ColorName.colorSubtitle,
  );

  /// Water add button label — 14 / w590 / line 14 / white 60%
  static TextStyle get waterAddLabel => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight(590),
    fontSize: 14,
    height: 1,
    letterSpacing: 14 * -0.015,
    color: ColorName.colorWhite.withValues(alpha: 0.6),
  );

  /// Water reminder row label — 18 / Semibold / secondary 60%
  static TextStyle get waterReminderLabel => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight(590),
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: 18 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Water reminder value — 18 / Bold / primary
  static TextStyle get waterReminderValue => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: 18 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Water glass size label (unselected) — 18 / Bold / secondary 60%
  static TextStyle get waterGlassSizeLabel => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: 18 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Water glass size label (selected) — 18 / Bold / primary
  static TextStyle get waterGlassSizeLabelSelected => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: 18 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Steps page date — 18 / Semibold
  static TextStyle get stepsToday => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Steps hero amount — 48 / Semibold
  static TextStyle get stepsHeroAmount => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 48,
    height: 56 / 48,
    letterSpacing: -1.0,
    color: ColorName.colorTitle,
  );

  /// Steps unit — 20 / Semibold
  static TextStyle get stepsUnit => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 28 / 20,
    letterSpacing: -0.4,
    color: ColorName.colorTitle,
  );

  /// Steps goal achieved — 18 / Semibold / orange
  static TextStyle get stepsGoalAchieved => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: -0.5,
    color: ColorName.colorStepsAction,
  );

  /// Steps daily target — 16 / Semibold
  static TextStyle get stepsDailyTarget => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 21 / 16,
    letterSpacing: 16 * -0.015,
    color: ColorName.colorSubtitle,
  );

  static TextStyle get stepsDailyTargetBold => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    height: 21 / 16,
    letterSpacing: 16 * -0.015,
    color: ColorName.colorSubtitle,
  );

  /// Steps add button label — 14 / white 60%
  static TextStyle get stepsAddLabel => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight(590),
    fontSize: 14,
    height: 1,
    letterSpacing: 14 * -0.015,
    color: ColorName.colorWhite.withValues(alpha: 0.6),
  );

  /// Steps stat label — 13 / Medium / secondary 60%
  static TextStyle get stepsStatLabel => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 18 / 13,
    letterSpacing: 13 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Steps stat value — 18 / Semibold
  static TextStyle get stepsStatValue => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: -0.3,
    color: ColorName.colorTitle,
  );

  /// Steps section title — 18 / Semibold
  static TextStyle get stepsSectionTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: -0.4,
    color: ColorName.colorTitle,
  );

  /// Steps weekday label — 12 / Medium
  static TextStyle get stepsWeekday => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 12 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.55),
  );

  /// Body History page title — 24 / Semibold
  static TextStyle get bodyHistoryTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 32 / 24,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Weight History card title — 18 / Semibold
  static TextStyle get bodyHistoryTitleSmall => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Body History card section title — 16 / Semibold
  static TextStyle get bodyCardTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Body History weight value — 40 / Semibold
  static TextStyle get bodyWeightValue => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 40,
    height: 48 / 40,
    letterSpacing: -0.8,
    color: ColorName.colorTitle,
  );

  /// Body History kg unit — 16 / Semibold / secondary 60%
  static TextStyle get bodyWeightUnit => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 16 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Body History update button — 16 / Semibold / white
  static TextStyle get bodyUpdateButton => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1,
    letterSpacing: -0.3,
    color: ColorName.colorWhite,
  );

  /// Body History bound value — 16 / Semibold
  static TextStyle get bodyBoundValue => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 22 / 16,
    letterSpacing: -0.3,
    color: ColorName.colorTitle,
  );

  /// Body History bound label — 13 / Medium / secondary 60%
  static TextStyle get bodyBoundLabel => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 18 / 13,
    letterSpacing: 13 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Body History progress % — 16 / Semibold
  static TextStyle get bodyProgressPercent => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 22 / 16,
    letterSpacing: -0.3,
    color: ColorName.colorTitle,
  );

  /// Body History BMI value — 32 / Semibold
  static TextStyle get bodyBmiValue => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 32,
    height: 40 / 32,
    letterSpacing: -0.6,
    color: ColorName.colorTitle,
  );

  /// Body History BMI status — 16 / Semibold / orange
  static TextStyle get bodyBmiStatus => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: -0.3,
    color: ColorName.colorStepsFill,
  );

  /// Body History BMI tick — 11 / Semibold / secondary 60%
  static TextStyle get bodyBmiTick => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 11,
    height: 16 / 11,
    letterSpacing: 11 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Body History chart axis — 10 / Regular / secondary 60%
  static TextStyle get bodyChartAxis => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w400,
    fontSize: 10,
    height: 1,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Body History segment active — 16 / Semibold
  static TextStyle get bodySegmentActive => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 16 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Body History segment idle — 16 / Semibold / secondary 60%
  static TextStyle get bodySegmentIdle => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 16 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Body History chart tooltip — 13 / Semibold / white
  static TextStyle get bodyChartTooltip => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    height: 1,
    color: ColorName.colorWhite,
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

  /// Profile user name — 18 / Semibold
  static TextStyle get profileName => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: 18 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Profile Premium badge — 14 / Semibold
  static TextStyle get profilePremiumBadge => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 14 * -0.015,
    color: ColorName.colorWhite,
  );

  /// Profile section title — 14 / Semibold
  static TextStyle get profileSectionTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Profile row title — 15 / Semibold
  static TextStyle get profileRowTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 16 / 15,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Profile row subtitle — 14 / Semibold / 60%
  static TextStyle get profileRowSubtitle => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 14 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Profile premium card title — 18 / Semibold
  static TextStyle get profilePremiumTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: -0.5,
    color: ColorName.colorWhite,
  );

  /// Profile premium card subtitle — 14 / Medium / 75%
  static TextStyle get profilePremiumSubtitle => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 14 * -0.025,
    color: ColorName.colorWhite.withValues(alpha: 0.75),
  );

  /// Profile Get Premium CTA — 14 / Semibold
  static TextStyle get profileGetPremium => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 14 * -0.02,
    color: ColorName.colorTitle,
  );

  /// Profile logout — 15 / Semibold
  static TextStyle get profileLogout => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 16 / 15,
    letterSpacing: -0.5,
    color: ColorName.colorOptionNegative,
  );

  /// Edit Profile / selection sheet title — 24 / Semibold / -4.5%
  static TextStyle get selectionSheetTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 32 / 24,
    letterSpacing: 24 * -0.045,
    color: ColorName.colorTitle,
  );

  /// Edit Profile title — 24 / Semibold
  static TextStyle get editProfileTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 32 / 24,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Edit Profile avatar initials — 22.5 / Medium
  static TextStyle get editProfileInitials => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 22.5,
    height: 24.75 / 22.5,
    letterSpacing: 22.5 * -0.02,
    color: ColorName.colorWhite,
  );

  /// Edit Profile change photo — 15 / Semibold / brand
  static TextStyle get editProfileChangePhoto => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 20 / 15,
    letterSpacing: 15 * -0.025,
    color: ColorName.colorBrandStrong,
  );

  /// Edit Profile field label — 15 / Semibold / subtitle 75%
  static TextStyle get editProfileLabel => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 16 / 15,
    letterSpacing: -0.5,
    color: ColorName.colorSubtitle.withValues(alpha: 0.75),
  );

  /// Edit Profile field value — 15 / Semibold
  static TextStyle get editProfileValue => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 16 / 15,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Edit Profile food chip — 12 / Semibold
  static TextStyle get editProfileChip => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Edit Profile skipped food chip — 12 / Semibold / negative v2
  static TextStyle get editProfileChipNegative => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: -0.5,
    color: ColorName.colorNegativeV2,
  );

  /// Weight dialog title — 24 / Semibold / -0.5
  static TextStyle get weightDialogTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 32 / 24,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Weight dialog subtitle (Today) — 16 / Semibold / secondary 60%
  static TextStyle get weightDialogSubtitle => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 16 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Weight dialog unit toggle label — 16 / Semibold
  static TextStyle get weightDialogUnitLabel => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 16 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Weight dialog value — 32 / Semibold
  static TextStyle get weightDialogValue => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 32,
    height: 40 / 32,
    letterSpacing: 32 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Weight dialog value unit — 16 / Semibold / secondary 60%
  static TextStyle get weightDialogValueUnit => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 16 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Notifications date header — 14 / Semibold / -0.5
  static TextStyle get notificationsDate => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: -0.5,
    color: ColorName.colorTitle,
  );

  /// Notifications card title — 16 / Semibold / -1.5%
  static TextStyle get notificationsCardTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 16 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Notifications time — 12 / Medium / secondary 60%
  static TextStyle get notificationsTime => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 12 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Notifications body — 15 / Medium / secondary 60%
  static TextStyle get notificationsBody => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    height: 24 / 15,
    letterSpacing: 15 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Notifications body emphasis — 15 / Bold
  static TextStyle get notificationsBodyEmphasis => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 15,
    height: 24 / 15,
    letterSpacing: 15 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Notifications empty title — 18 / Semibold / -1.5%
  static TextStyle get notificationsEmptyTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: 18 * -0.015,
    color: ColorName.colorTitle,
  );

  /// Notifications empty subtitle — 15 / Medium / secondary 60%
  static TextStyle get notificationsEmptySubtitle => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    height: 24 / 15,
    letterSpacing: 15 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// FAQ question — 16 / Semibold / -4%
  static TextStyle get faqQuestion => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 16 * -0.04,
    color: ColorName.colorTitle,
  );

  /// FAQ answer — 14 / Medium / secondary 60%
  static TextStyle get faqAnswer => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 24 / 14,
    letterSpacing: 14 * -0.015,
    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
  );

  /// Chat header title — 18 / Semibold / white
  static TextStyle get chatCoachName => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: -0.5,
    color: ColorName.colorWhite,
  );

  /// Chat greeting — 24 / Semibold / white
  static TextStyle get chatGreeting => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 32 / 24,
    letterSpacing: -0.5,
    color: ColorName.colorWhite,
  );

  /// Chat suggestion chip — 16 / Semibold / white
  static TextStyle get chatSuggestion => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 16 * -0.015,
    color: ColorName.colorWhite,
  );

  /// Chat input hint — 16 / Semibold / white 80%
  static TextStyle get chatInputHint => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: -0.5,
    color: ColorName.colorWhite.withValues(alpha: 0.8),
  );

  /// Chat input text — 16 / Semibold / white
  static TextStyle get chatInputText => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: -0.5,
    color: ColorName.colorWhite,
  );

  /// Chat bubble message — 16 / Semibold / white
  static TextStyle get chatBubbleMessage => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 16 * -0.015,
    color: ColorName.colorWhite,
  );

  /// Chat history meta — 14 / Medium / white 60%
  static TextStyle get chatHistoryMeta => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 14 * -0.015,
    color: ColorName.colorWhite.withValues(alpha: 0.6),
  );

  /// Chat history popup — 15 / Semibold / white
  static TextStyle get chatHistoryMenuItem => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 22 / 15,
    letterSpacing: 15 * -0.015,
    color: ColorName.colorWhite,
  );

  /// Chat history delete — 15 / Semibold / red
  static TextStyle get chatHistoryMenuDelete => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 22 / 15,
    letterSpacing: 15 * -0.015,
    color: ColorName.colorNegativeV2,
  );

  /// Latest chats empty title — 20 / Semibold / white
  static TextStyle get chatHistoryEmptyTitle => const TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 28 / 20,
    letterSpacing: -0.5,
    color: ColorName.colorWhite,
  );

  /// Latest chats empty subtitle — 15 / Medium / white 60%
  static TextStyle get chatHistoryEmptySubtitle => TextStyle(
    fontFamily: FontFamily.sFProDisplay,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    height: 24 / 15,
    letterSpacing: 15 * -0.015,
    color: ColorName.colorWhite.withValues(alpha: 0.6),
  );
}
