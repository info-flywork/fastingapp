import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

enum PlansChipTone { breakfast, dinner, advanced }

/// Plans sekmesi kart modeli.
@immutable
final class PlansCardData {
  const PlansCardData({
    required this.title,
    required this.subtitleKey,
    required this.chipKey,
    required this.tone,
    required this.intensity,
    required this.watermark,
    this.isLocked = false,
  });

  final String title;
  final String subtitleKey;
  final String chipKey;
  final PlansChipTone tone;
  final int intensity;
  final String watermark;
  final bool isLocked;

  Color get accentColor => switch (tone) {
        PlansChipTone.breakfast => ColorName.colorMealPositive,
        PlansChipTone.dinner => ColorName.colorPlanChipDinnerText,
        PlansChipTone.advanced => ColorName.colorMealPositive,
      };

  Color get chipBg => switch (tone) {
        PlansChipTone.breakfast => ColorName.colorPlanChipBreakfastBg,
        PlansChipTone.dinner => ColorName.colorPlanChipDinnerBg,
        PlansChipTone.advanced => ColorName.colorPlanChipBreakfastBg,
      };

  Color get chipFg => switch (tone) {
        PlansChipTone.breakfast => ColorName.colorPlanChipBreakfastText,
        PlansChipTone.dinner => ColorName.colorPlanChipDinnerText,
        PlansChipTone.advanced => ColorName.colorPlanChipBreakfastText,
      };

  String get selectionKey => '$title|$chipKey|${tone.name}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlansCardData && selectionKey == other.selectionKey;

  @override
  int get hashCode => selectionKey.hashCode;
}

/// Plans sekmesi — her seviye 2 bağımsız yatay satır.
abstract final class PlansCatalog {
  /// Başlangıç — üst satır (kahvaltı atla).
  static const beginnerRow1 = <PlansCardData>[
    PlansCardData(
      title: '16-8',
      subtitleKey: 'plans.subtitle_16_8',
      chipKey: 'plans.chip_skip_breakfast',
      tone: PlansChipTone.breakfast,
      intensity: 1,
      watermark: '7',
    ),
    PlansCardData(
      title: '15-9',
      subtitleKey: 'plans.subtitle_15_9',
      chipKey: 'plans.chip_skip_breakfast',
      tone: PlansChipTone.breakfast,
      intensity: 2,
      watermark: '7',
    ),
    PlansCardData(
      title: '14-10',
      subtitleKey: 'plans.subtitle_14_10',
      chipKey: 'plans.chip_skip_breakfast',
      tone: PlansChipTone.breakfast,
      intensity: 1,
      watermark: '7',
    ),
  ];

  /// Başlangıç — alt satır (akşam yemeği atla).
  static const beginnerRow2 = <PlansCardData>[
    PlansCardData(
      title: '16-8',
      subtitleKey: 'plans.subtitle_16_8',
      chipKey: 'plans.chip_skip_dinner',
      tone: PlansChipTone.dinner,
      intensity: 1,
      watermark: '7',
    ),
    PlansCardData(
      title: '15-9',
      subtitleKey: 'plans.subtitle_15_9',
      chipKey: 'plans.chip_skip_dinner',
      tone: PlansChipTone.dinner,
      intensity: 2,
      watermark: '7',
    ),
    PlansCardData(
      title: '14-10',
      subtitleKey: 'plans.subtitle_14_10',
      chipKey: 'plans.chip_skip_dinner',
      tone: PlansChipTone.dinner,
      intensity: 1,
      watermark: '7',
    ),
  ];

  /// İleri — üst satır.
  static const advancedRow1 = <PlansCardData>[
    PlansCardData(
      title: '19-5',
      subtitleKey: 'plans.subtitle_19_5',
      chipKey: 'plans.chip_one_meal',
      tone: PlansChipTone.advanced,
      intensity: 3,
      watermark: '7',
      isLocked: true,
    ),
    PlansCardData(
      title: '20-4',
      subtitleKey: 'plans.subtitle_20_4',
      chipKey: 'plans.chip_one_meal',
      tone: PlansChipTone.advanced,
      intensity: 3,
      watermark: '7',
      isLocked: true,
    ),
    PlansCardData(
      title: 'OMAD',
      subtitleKey: 'plans.subtitle_omad',
      chipKey: 'plans.chip_one_meal',
      tone: PlansChipTone.dinner,
      intensity: 4,
      watermark: '7',
      isLocked: true,
    ),
  ];

  /// İleri — alt satır.
  static const advancedRow2 = <PlansCardData>[
    PlansCardData(
      title: '18-6',
      subtitleKey: 'plans.subtitle_18_6',
      chipKey: 'plans.chip_one_meal',
      tone: PlansChipTone.advanced,
      intensity: 3,
      watermark: '7',
      isLocked: true,
    ),
    PlansCardData(
      title: '20-4',
      subtitleKey: 'plans.subtitle_20_4',
      chipKey: 'plans.chip_one_meal',
      tone: PlansChipTone.dinner,
      intensity: 4,
      watermark: '7',
      isLocked: true,
    ),
    PlansCardData(
      title: 'OMAD',
      subtitleKey: 'plans.subtitle_omad',
      chipKey: 'plans.chip_one_meal',
      tone: PlansChipTone.dinner,
      intensity: 4,
      watermark: '7',
      isLocked: true,
    ),
  ];
}
