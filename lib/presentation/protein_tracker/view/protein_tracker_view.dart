import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/horseshoe_arc.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Kalori takibi → Protein takibi.
final class ProteinTrackerView extends StatelessWidget {
  const ProteinTrackerView({super.key});

  static const _meals = <_Meal>[
    _Meal(
      image: _MealImage.eggs,
      titleKey: 'protein_page.meal_eggs_title',
      metaKey: 'protein_page.meal_eggs_meta',
      proteinKey: 'protein_page.meal_eggs_protein',
      kcalKey: 'protein_page.meal_eggs_kcal',
    ),
    _Meal(
      image: _MealImage.salad,
      titleKey: 'protein_page.meal_salad_title',
      metaKey: 'protein_page.meal_salad_meta',
      proteinKey: 'protein_page.meal_salad_protein',
      kcalKey: 'protein_page.meal_salad_kcal',
    ),
    _Meal(
      image: _MealImage.yogurt,
      titleKey: 'protein_page.meal_yogurt_title',
      metaKey: 'protein_page.meal_yogurt_meta',
      proteinKey: 'protein_page.meal_yogurt_protein',
      kcalKey: 'protein_page.meal_yogurt_kcal',
    ),
  ];

  static const _week = <int>[125, 80, 90, 130, 40, 60, 70];

  static const _dayKeys = [
    'sleep_page.day_mon',
    'sleep_page.day_tue',
    'sleep_page.day_wed',
    'sleep_page.day_thu',
    'sleep_page.day_fri',
    'sleep_page.day_sat',
    'sleep_page.day_sun',
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorBodyPageBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 56,
                width: double.infinity,
                child: _ProteinHeader(),
              ),
              Expanded(
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    const _ProteinArc(),
                    const SizedBox(height: 8),
                    Text(
                      'protein_page.today'.tr(),
                      style: AppTextStyles.sleepSectionTitle,
                    ),
                    const SizedBox(height: 4),
                    for (var i = 0; i < _meals.length; i++) ...[
                      _MealCard(meal: _meals[i]),
                      if (i != _meals.length - 1) const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'protein_page.week'.tr(),
                      style: AppTextStyles.sleepSectionTitle,
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < _week.length; i++) ...[
                      _WeekBar(labelKey: _dayKeys[i], grams: _week[i]),
                      if (i != _week.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              _CalculateBar(bottomInset: math.max(bottom, 24)),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ProteinHeader extends StatelessWidget {
  const _ProteinHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _CircleBackButton(onTap: () => context.pop()),
          Expanded(
            child: Text(
              'protein_page.title'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.sleepTitle,
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

final class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorWhite,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: ColorName.colorBlack.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Assets.icons.solarAltArrowUpLineDuotone.svg(
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                ColorName.colorTitle,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ProteinArc extends StatelessWidget {
  const _ProteinArc();

  static const _progress = 75 / 120;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: _progress),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) {
        return Center(
          child: SizedBox(
            width: HorseshoeArc.diameterDefault,
            height: HorseshoeArc.diameterDefault * 0.82,
            child: Stack(
              alignment: Alignment.center,
              children: [
                HorseshoeArc(
                  progress: progress,
                  minProgress: 0,
                  trackColor: ColorName.colorUnitToggleBg,
                ),
                child!,
              ],
            ),
          ),
        );
      },
      child: const _ArcCaption(),
    );
  }
}

final class _ArcCaption extends StatelessWidget {
  const _ArcCaption();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('protein_page.current'.tr(), style: AppTextStyles.proteinHero),
        Text('protein_page.goal'.tr(), style: AppTextStyles.proteinGoal),
      ],
    );
  }
}

enum _MealImage { eggs, salad, yogurt }

final class _Meal {
  const _Meal({
    required this.image,
    required this.titleKey,
    required this.metaKey,
    required this.proteinKey,
    required this.kcalKey,
  });

  final _MealImage image;
  final String titleKey;
  final String metaKey;
  final String proteinKey;
  final String kcalKey;

  AssetGenImage get asset => switch (image) {
    _MealImage.eggs => Assets.images.scramlbedEggs,
    _MealImage.salad => Assets.images.grilledSalad,
    _MealImage.yogurt => Assets.images.yogurt,
  };
}

final class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});

  final _Meal meal;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorName.colorBlack.withValues(alpha: 0.05),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipOval(
              child: meal.asset.image(width: 48, height: 48, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.titleKey.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.proteinMealTitle,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meal.metaKey.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.proteinMealMeta,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  meal.proteinKey.tr(),
                  style: AppTextStyles.proteinMealGrams,
                ),
                Text(meal.kcalKey.tr(), style: AppTextStyles.proteinMealKcal),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _WeekBar extends StatelessWidget {
  const _WeekBar({required this.labelKey, required this.grams});

  final String labelKey;
  final int grams;

  static const _maxGrams = 130.0;

  @override
  Widget build(BuildContext context) {
    final target = (grams / _maxGrams).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(labelKey.tr(), style: AppTextStyles.sleepDayLabel),
        ),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: target),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  const reserve = 52.0;
                  final barMax = math.max(0, constraints.maxWidth - reserve);
                  return Row(
                    children: [
                      SizedBox(
                        width: barMax * animated,
                        height: 14,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: ColorName.colorPremiumGradientStart,
                            borderRadius: BorderRadius.all(
                              Radius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'protein_page.grams'.tr(args: ['$grams']),
                        style: AppTextStyles.sleepDayLabel,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

final class _CalculateBar extends StatelessWidget {
  const _CalculateBar({required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
        child: AppButton(
          label: 'protein_page.calculate'.tr(),
          onPressed: () => context.pushNamed(RoutePaths.caloriesCamera.name),
          decoration: AppButtonDecoration.hungerResult(),
        ),
      ),
    );
  }
}
