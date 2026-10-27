import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:fastingapp/core/utils/weight_progress.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/app_shimmer.dart';
import 'package:fastingapp/core/widgets/arc_progress_gauge.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_stepper_field.dart';
import 'package:fastingapp/core/widgets/weight_progress_bar.dart';
import 'package:fastingapp/domain/nutrition/meals_repository.dart';
import 'package:fastingapp/domain/nutrition/nutrition_repository.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:fastingapp/domain/trackers/weight_store.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/fasting/fasting_finish_flow.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_state.dart';
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

    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || errorMessage == null) return;
        AppSnackbar.show(
          context: context,
          text: errorMessage!,
          type: SnackBarType.failure,
        );
        setState(() => errorMessage = null);
      });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorBodyPageBg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: showShimmer
                  ? _CaloriesShimmerBody(
                      topInset: top,
                      headerHeight: headerHeight,
                      cardOverlap: _cardOverlap,
                    )
                  : RefreshIndicator(
                      onRefresh: loadDay,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        ),
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
                                kcalGoal: kcalGoal,
                                height: headerHeight,
                                onEditGoal: kcalGoal == null
                                    ? null
                                    : () => unawaited(onEditKcalGoal()),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: headerHeight - _cardOverlap + 24,
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _CalorieTrackingCard(
                                        carbsG: carbsG,
                                        proteinG: proteinG,
                                        fatG: fatG,
                                        carbsProgress: carbsProgress,
                                        proteinProgress: proteinProgress,
                                        fatProgress: fatProgress,
                                      ),
                                      const SizedBox(height: 16),
                                      AppButton(
                                        label: 'calories_page.protein_tracker'
                                            .tr(),
                                        onPressed: () =>
                                            unawaited(onProteinTracker()),
                                        decoration: AppButtonDecoration.dark(),
                                        showIcon: false,
                                      ),
                                      const SizedBox(height: 16),
                                      _BurnedCard(
                                        burnedKcal: burnedKcal,
                                        startKg: startKg,
                                        goalKg: goalKg,
                                        progress: weightProgress,
                                      ),
                                      const SizedBox(height: 20),
                                      OnboardingStepperField(
                                        label: 'calories_page.add_daily_manual'
                                            .tr(),
                                        displayValue: '$manualKcal',
                                        unit: 'calories_page.kcal'.tr(),
                                        onDecrement: onManualDecrement,
                                        onIncrement: onManualIncrement,
                                      ),
                                      if (manualKcal > 0) ...[
                                        const SizedBox(height: 12),
                                        AppButton(
                                          label: 'calories_page.add_manual_cta'
                                              .tr(args: ['$manualKcal']),
                                          onPressed: savingManual
                                              ? null
                                              : () => unawaited(onManualAdd()),
                                          decoration:
                                              AppButtonDecoration.hungerResult(),
                                          showIcon: false,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

/// İlk yüklemede full-page spinner yerine iskelet.
final class _CaloriesShimmerBody extends StatelessWidget {
  const _CaloriesShimmerBody({
    required this.topInset,
    required this.headerHeight,
    required this.cardOverlap,
  });

  final double topInset;
  final double headerHeight;
  final double cardOverlap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _CaloriesHeader(
              topInset: topInset,
              eatenKcal: 0,
              kcalGoal: null,
              height: headerHeight,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: headerHeight - cardOverlap + 24),
              const AppShimmer(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      AppShimmerBone(
                        height: 168,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      SizedBox(height: 16),
                      AppShimmerBone(
                        height: 52,
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                      SizedBox(height: 16),
                      AppShimmerBone(
                        height: 140,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      SizedBox(height: 20),
                      AppShimmerBone(
                        height: 72,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ],
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
    required this.kcalGoal,
    required this.height,
    this.onEditGoal,
  });

  final double topInset;
  final int eatenKcal;
  final int? kcalGoal;

  /// Hedefe dokununca düzenle (önceden değiştirilemiyordu).
  final VoidCallback? onEditGoal;
  final double height;

  static const _mascotSize = 168.0;

  /// header_back.png — 1448×1086
  static const imageAspect = 1086 / 1448;

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat('#,###');
    final eatenFormatted = format.format(eatenKcal);
    final goal = kcalGoal;
    // Hedef yoksa yenilen; hedef aşıldıysa fazlası; değilse kalan
    // (önceden hedef yokken "0 kcal over", kalan hiç gösterilmiyordu).
    final (int hero, String heroLabel) = goal == null
        ? (eatenKcal, 'calories_page.kcal_eaten')
        : eatenKcal > goal
        ? (eatenKcal - goal, 'calories_page.kcal_over')
        : (goal - eatenKcal, 'calories_page.kcal_left');

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
                if (goal != null) ...[
                  Text(
                    'calories_page.eaten'.tr(args: [eatenFormatted]),
                    style: AppTextStyles.caloriesEatenLabel,
                  ),
                  const SizedBox(height: 2),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      format.format(hero),
                      style: AppTextStyles.caloriesHeroValue,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 14),
                      child: Text(
                        heroLabel.tr(),
                        style: AppTextStyles.caloriesOverLabel,
                      ),
                    ),
                  ],
                ),
                if (goal != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onEditGoal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'calories_page.goal_fmt'.tr(
                            args: [format.format(goal)],
                          ),
                          style: AppTextStyles.caloriesEatenLabel,
                        ),
                        const SizedBox(width: 4),
                        Assets.icons.solarPen2LineDuotone.svg(
                          width: 16,
                          height: 16,
                        ),
                      ],
                    ),
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
  const _CalorieTrackingCard({
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
    required this.carbsProgress,
    required this.proteinProgress,
    required this.fatProgress,
  });

  final double carbsG;
  final double proteinG;
  final double fatG;
  final double carbsProgress;
  final double proteinProgress;
  final double fatProgress;

  String _grams(double g) => '${g.round()}g';

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
                    progress: carbsProgress,
                    color: ColorName.colorPremiumGradientStart,
                    valueText: _grams(carbsG),
                    label: 'calories_page.carbs'.tr(),
                    size: 100,
                    valueStyle: AppTextStyles.caloriesMacroValue,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ArcProgressGauge(
                    progress: proteinProgress,
                    color: ColorName.colorStepsFill,
                    valueText: _grams(proteinG),
                    label: 'calories_page.protein'.tr(),
                    size: 100,
                    valueStyle: AppTextStyles.caloriesMacroValue,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ArcProgressGauge(
                    progress: fatProgress,
                    color: ColorName.colorMetabolicFast,
                    valueText: _grams(fatG),
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
  const _BurnedCard({
    required this.burnedKcal,
    required this.progress,
    this.startKg,
    this.goalKg,
  });

  final int burnedKcal;
  final double? startKg;
  final double? goalKg;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final hasWeight = startKg != null && goalKg != null;
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
              Text('$burnedKcal', style: AppTextStyles.caloriesBurnedValue),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  'calories_page.kcal'.tr(),
                  style: AppTextStyles.caloriesBurnedUnit,
                ),
              ),
            ],
          ),
          if (hasWeight) ...[
            const SizedBox(height: 16),
            WeightProgressBar(progress: progress),
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
                          text:
                              '${startKg!.toStringAsFixed(1)}${'home.weight_unit'.tr()}',
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
                        text:
                            '${goalKg!.toStringAsFixed(1)}${'home.weight_unit'.tr()}',
                        style: AppTextStyles.homeWeightBoundValue,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
