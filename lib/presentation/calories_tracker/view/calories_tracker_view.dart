import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/arc_progress_gauge.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_stepper_field.dart';
import 'package:fastingapp/core/widgets/weight_progress_bar.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/calories_tracker_view_mixin.dart';

/// Kalori takibi — header + makro gauge + yakılan + manuel giriş.
final class CaloriesTrackerView extends StatefulWidget {
  const CaloriesTrackerView({super.key});

  @override
  State<CaloriesTrackerView> createState() => _CaloriesTrackerViewState();
}

class _CaloriesTrackerViewState extends State<CaloriesTrackerView>
    with CaloriesTrackerViewMixin {
  static const _cardOverlap = 80.0;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width;
    final headerHeight = width * _CaloriesHeader.imageAspect;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorBodyPageBg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _CaloriesHeader(
                        topInset: top,
                        eatenKcal: eatenKcal,
                        overKcal: overKcal,
                        height: headerHeight,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: headerHeight - _cardOverlap + 24),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _CalorieTrackingCard(),
                              const SizedBox(height: 16),
                              AppButton(
                                label: 'calories_page.protein_tracker'.tr(),
                                onPressed: onProteinTracker,
                                decoration: AppButtonDecoration.dark(),
                                showIcon: false,
                              ),
                              const SizedBox(height: 16),
                              const _BurnedCard(),
                              const SizedBox(height: 20),
                              OnboardingStepperField(
                                label: 'calories_page.add_daily_manual'.tr(),
                                displayValue: '$manualKcal',
                                unit: 'calories_page.kcal'.tr(),
                                onDecrement: onManualDecrement,
                                onIncrement: onManualIncrement,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _CalculateBar(
              bottomInset: math.max(bottom, 24),
              onCalculate: onCalculate,
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma Frame 48096339 — üst radius 32, pad 16/16/24/16.
final class _CalculateBar extends StatelessWidget {
  const _CalculateBar({required this.bottomInset, required this.onCalculate});

  final double bottomInset;
  final VoidCallback onCalculate;

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
          label: 'calories_page.calculate'.tr(),
          onPressed: onCalculate,
          decoration: AppButtonDecoration.hungerResult(),
        ),
      ),
    );
  }
}

final class _CaloriesHeader extends StatelessWidget {
  const _CaloriesHeader({
    required this.topInset,
    required this.eatenKcal,
    required this.overKcal,
    required this.height,
  });

  final double topInset;
  final int eatenKcal;
  final int overKcal;
  final double height;

  static const _mascotSize = 168.0;

  /// header_back.png — 1448×1086
  static const imageAspect = 1086 / 1448;

  @override
  Widget build(BuildContext context) {
    final eatenFormatted = NumberFormat('#,###').format(eatenKcal);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AppImages.headerBack.image(
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned(
            right: 8,
            top: topInset,
            child: Transform.scale(
              scale: 1.1,
              child: AppImages.caloriesTracker.image(
                width: _mascotSize,
                height: _mascotSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          Positioned(
            left: 22,
            top: topInset + 2,
            right: _mascotSize * 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'calories_page.eaten'.tr(args: [eatenFormatted]),
                  style: AppTextStyles.caloriesEatenLabel,
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$overKcal', style: AppTextStyles.caloriesHeroValue),
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 14),
                      child: Text(
                        'calories_page.kcal_over'.tr(),
                        style: AppTextStyles.caloriesOverLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _CalorieTrackingCard extends StatelessWidget {
  const _CalorieTrackingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppImages.flameCalories.image(
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'calories_page.calorie_tracking'.tr(),
                  style: AppTextStyles.caloriesCardTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Center(
                  child: ArcProgressGauge(
                    progress: 0.72,
                    color: ColorName.colorPremiumGradientStart,
                    valueText: '271g',
                    label: 'calories_page.carbs'.tr(),
                    size: 100,
                    valueStyle: AppTextStyles.caloriesMacroValue,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ArcProgressGauge(
                    progress: 0.55,
                    color: ColorName.colorStepsFill,
                    valueText: '150g',
                    label: 'calories_page.protein'.tr(),
                    size: 100,
                    valueStyle: AppTextStyles.caloriesMacroValue,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ArcProgressGauge(
                    progress: 0.68,
                    color: ColorName.colorMetabolicFast,
                    valueText: '280g',
                    label: 'calories_page.fat'.tr(),
                    size: 100,
                    valueStyle: AppTextStyles.caloriesMacroValue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _BurnedCard extends StatelessWidget {
  const _BurnedCard();

  static const _burnedKcal = 651;
  static const _startKg = 112.2;
  static const _goalKg = 75.2;
  static const _progress = 0.55;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👏', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'calories_page.burned'.tr(),
                style: AppTextStyles.caloriesCardTitle,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$_burnedKcal', style: AppTextStyles.caloriesBurnedValue),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  'calories_page.kcal'.tr(),
                  style: AppTextStyles.caloriesBurnedUnit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const WeightProgressBar(progress: _progress),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${'calories_page.start'.tr()} ',
                        style: AppTextStyles.homeWeightBoundLabel,
                      ),
                      TextSpan(
                        text: '$_startKg${'home.weight_unit'.tr()}',
                        style: AppTextStyles.homeWeightBoundValue,
                      ),
                    ],
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${'calories_page.goal'.tr()} ',
                      style: AppTextStyles.homeWeightBoundLabel,
                    ),
                    TextSpan(
                      text: '$_goalKg${'home.weight_unit'.tr()}',
                      style: AppTextStyles.homeWeightBoundValue,
                    ),
                  ],
                ),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
