import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/domain/fasting/plan_catalog_repository.dart';
import 'package:fastingapp/domain/fasting/weekly_schedule.dart';
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
    bool isLocked = false,
    this.code,
    this.titleKey,
  }) : _lockedFallback = isLocked;

  final String title;

  /// Başlıktan türetilemeyen plan kodu (ör. `alternate_day`).
  final String? code;

  /// Çevrilen başlık (ör. "Gün aşırı"); yoksa [title] gösterilir.
  final String? titleKey;

  String get displayTitle => titleKey?.tr() ?? title;
  final String subtitleKey;
  final String chipKey;
  final PlansChipTone tone;
  final int intensity;
  final String watermark;

  /// Katalog yüklenemezse kullanılan yerel varsayılan.
  final bool _lockedFallback;

  /// Premium plan mı (kilit); kaynak sunucu kataloğu (`/catalog/plans`).
  bool get isLocked =>
      PlanCatalogRepository.instance?.entry(planCode)?.isPremium ??
      _lockedFallback;

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

  /// Backend plan kodu (`seeds/plans.json`): `16-8` → `16_8`, `OMAD` → `omad`.
  String get planCode => code ?? title.toLowerCase().replaceAll('-', '_');

  bool get isWeekly => WeeklyRules.isWeekly(planCode);

  /// `PUT /plans/current` zamanlaması; ileri seviye planlarda sunucu
  /// varsayılanı.
  String? get timing => switch (tone) {
    PlansChipTone.breakfast => 'skipBreakfast',
    PlansChipTone.dinner => 'skipDinner',
    PlansChipTone.advanced => null,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlansCardData && selectionKey == other.selectionKey;

  @override
  int get hashCode => selectionKey.hashCode;
}

/// Plans sekmesi — her seviye 2 bağımsız yatay satır.
abstract final class PlansCatalog {
  static const all = [
    ...beginnerRow1,
    ...beginnerRow2,
    ...advancedRow1,
    ...advancedRow2,
    ...weeklyRow,
  ];

  /// Haftalık planlar (hepsi premium; günleri kullanıcı seçer).
  static const weeklyRow = <PlansCardData>[
    PlansCardData(
      title: '5-2',
      subtitleKey: 'plans.subtitle_5_2',
      chipKey: 'plans.chip_weekly',
      tone: PlansChipTone.breakfast,
      intensity: 2,
      watermark: '7',
      isLocked: true,
    ),
    PlansCardData(
      title: '6-1',
      subtitleKey: 'plans.subtitle_6_1',
      chipKey: 'plans.chip_weekly',
      tone: PlansChipTone.breakfast,
      intensity: 2,
      watermark: '7',
      isLocked: true,
    ),
    PlansCardData(
      title: 'ADF',
      code: 'alternate_day',
      titleKey: 'plans.title_alternate_day',
      subtitleKey: 'plans.subtitle_alternate_day',
      chipKey: 'plans.chip_weekly',
      tone: PlansChipTone.dinner,
      intensity: 3,
      watermark: '7',
      isLocked: true,
    ),
    PlansCardData(
      title: 'Crescendo',
      code: 'crescendo',
      titleKey: 'plans.title_crescendo',
      subtitleKey: 'plans.subtitle_crescendo',
      chipKey: 'plans.chip_weekly',
      tone: PlansChipTone.breakfast,
      intensity: 2,
      watermark: '7',
      isLocked: true,
    ),
    PlansCardData(
      title: 'Custom',
      code: 'custom_weekly',
      titleKey: 'plans.title_custom_weekly',
      subtitleKey: 'plans.subtitle_custom_weekly',
      chipKey: 'plans.chip_weekly',
      tone: PlansChipTone.advanced,
      intensity: 2,
      watermark: '7',
      isLocked: true,
    ),
  ];

  /// Sunucudaki etkin plana karşılık gelen kart (kod + zamanlama; zamanlama
  /// eşleşmezse yalnızca kod). Katalogda yoksa null.
  static PlansCardData? forPlan(String? planCode, {String? timing}) {
    if (planCode == null) return null;
    final norm = timing?.toLowerCase().replaceAll('_', '');
    final sameCode = all.where((c) => c.planCode == planCode).toList();
    if (sameCode.isEmpty) return null;
    return sameCode.firstWhere(
      (c) => c.timing?.toLowerCase() == norm,
      orElse: () => sameCode.first,
    );
  }

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
