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
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/app_shimmer.dart';
import 'package:fastingapp/core/widgets/horseshoe_arc.dart';
import 'package:fastingapp/domain/nutrition/nutrition_repository.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Kalori takibi → Protein takibi (`GET /v1/nutrition/day` + `/week?metric=protein`).
final class ProteinTrackerView extends StatefulWidget {
  const ProteinTrackerView({super.key});

  @override
  State<ProteinTrackerView> createState() => _ProteinTrackerViewState();
}

class _ProteinTrackerViewState extends State<ProteinTrackerView> {
  final _nutrition = getIt<NutritionRepository>();

  /// Cache yoksa ilk frame'de shimmer; cache varken asla full-page loading yok.
  bool _showShimmer = false;
  bool _hasContent = false;

  /// İlk içerik sonrası gauge/bar animasyonu bir kez; sessiz refresh'te sıfırlama yok.
  bool _playEntrance = true;
  String? _error;
  NutritionDay _day = NutritionDay.empty();
  NutritionWeek _week = NutritionWeek.empty();

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
  void initState() {
    super.initState();
    _seedLocal();
    if (!_hasContent) {
      _showShimmer = true;
    } else {
      _scheduleEntranceDone();
    }
    unawaited(_load());
  }

  void _seedLocal() {
    final cachedDay = _nutrition.cachedDay();
    final cachedWeek = _nutrition.cachedWeek();
    if (cachedDay == null && cachedWeek == null) return;
    if (cachedDay != null) _day = cachedDay;
    if (cachedWeek != null) _week = cachedWeek;
    _hasContent = true;
  }

  void _scheduleEntranceDone() {
    if (!_playEntrance) return;
    Future<void>.delayed(const Duration(milliseconds: 950), () {
      if (!mounted || !_playEntrance) return;
      setState(() => _playEntrance = false);
    });
  }

  Future<void> _load({bool force = true}) async {
    final needShimmer = !_hasContent;
    if (needShimmer && mounted) {
      setState(() {
        _showShimmer = true;
        _error = null;
      });
    } else if (mounted) {
      setState(() => _error = null);
    }
    try {
      final results = await Future.wait([
        _nutrition.getDay(force: force),
        _nutrition.getWeek(force: force),
      ]);
      if (!mounted) return;
      final revealFromShimmer = _showShimmer || !_hasContent;
      setState(() {
        _day = results[0] as NutritionDay;
        _week = results[1] as NutritionWeek;
        _hasContent = true;
        _showShimmer = false;
      });
      if (revealFromShimmer) _scheduleEntranceDone();
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _showShimmer = false;
        _error = e.message;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _showShimmer = false;
        _error = errorMessageOf(e);
      });
    }
  }

  /// Protein hedefi (0–400 g, `PATCH /user/goals {proteinGoalG}`); önceden
  /// değiştirilemiyordu. Hedef gizliyse (sağlık bayrağı) düzenlenmez.
  Future<void> _editGoal(int current) async {
    final value = await AppDialogs.instance.showGoalStepper(
      context,
      title: 'protein_page.goal_title'.tr(),
      initial: current,
      min: 20,
      max: 400,
      step: 5,
      format: (v) => '$v g',
    );
    if (value == null || value == current || !mounted) return;
    try {
      await getIt<TrackersRepository>().updateGoals({'proteinGoalG': value});
      DataSync.afterWrite();
      if (mounted) await _load();
    } on Object catch (e) {
      if (mounted) AppSnackbar.showError(context, e);
    }
  }

  Future<void> _onCalculate() async {
    await context.pushNamed(RoutePaths.caloriesCamera.name);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final protein = _day.macros.protein;
    final currentG = protein.g.round();
    final goalG = protein.goalG?.round();
    final arcProgress = protein.progressOrZero;

    if (_error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _error == null) return;
        AppSnackbar.show(
          context: context,
          text: _error!,
          type: SnackBarType.failure,
        );
        setState(() => _error = null);
      });
    }

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
                child: _showShimmer
                    ? const _ProteinShimmerBody()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: ClampingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: goalG == null
                                  ? null
                                  : () => unawaited(_editGoal(goalG)),
                              child: _ProteinArc(
                                progress: arcProgress,
                                currentG: currentG,
                                goalG: goalG,
                                animate: _playEntrance,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'protein_page.today'.tr(),
                              style: AppTextStyles.sleepSectionTitle,
                            ),
                            const SizedBox(height: 4),
                            if (!_day.hasMeals)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Text(
                                  'protein_page.empty_meals'.tr(),
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.proteinMealMeta,
                                ),
                              )
                            else
                              for (var i = 0; i < _day.meals.length; i++) ...[
                                _MealCard(meal: _day.meals[i]),
                                if (i != _day.meals.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            const SizedBox(height: 24),
                            Text(
                              'protein_page.week'.tr(),
                              style: AppTextStyles.sleepSectionTitle,
                            ),
                            const SizedBox(height: 12),
                            ..._weekBars(goalG),
                          ],
                        ),
                      ),
              ),
              _CalculateBar(
                bottomInset: math.max(bottom, 24),
                onCalculate: _onCalculate,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _weekBars(int? goalG) {
    final days = _week.days;
    if (days.isEmpty) {
      return [
        for (var i = 0; i < 7; i++) ...[
          _WeekBar(
            labelKey: _dayKeys[i],
            grams: 0,
            maxGrams: (goalG ?? 120).toDouble(),
            animate: _playEntrance,
          ),
          if (i != 6) const SizedBox(height: 12),
        ],
      ];
    }
    final maxValue = days.fold<double>(0, (m, d) => math.max(m, d.value));
    final maxGrams = math.max(maxValue, (goalG ?? 0).toDouble()).clamp(1, 9999);
    return [
      for (var i = 0; i < days.length; i++) ...[
        _WeekBar(
          labelKey: _dayKeys[i.clamp(0, _dayKeys.length - 1)],
          grams: days[i].value.round(),
          maxGrams: maxGrams.toDouble(),
          animate: _playEntrance,
        ),
        if (i != days.length - 1) const SizedBox(height: 12),
      ],
    ];
  }
}

final class _ProteinShimmerBody extends StatelessWidget {
  const _ProteinShimmerBody();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: const [
          AppShimmerBone(
            height: 200,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          SizedBox(height: 16),
          AppShimmerBone(
            height: 24,
            width: 120,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          SizedBox(height: 12),
          AppShimmerBone(
            height: 120,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          SizedBox(height: 16),
          AppShimmerBone(
            height: 160,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ],
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
  const _ProteinArc({
    required this.progress,
    required this.currentG,
    required this.animate,
    this.goalG,
  });

  final double progress;
  final int currentG;
  final bool animate;
  final int? goalG;

  @override
  Widget build(BuildContext context) {
    Widget frame(double value) {
      return Center(
        child: SizedBox(
          width: HorseshoeArc.diameterDefault,
          height: HorseshoeArc.diameterDefault * 0.82,
          child: Stack(
            alignment: Alignment.center,
            children: [
              HorseshoeArc(
                progress: value,
                minProgress: 0,
                trackColor: ColorName.colorUnitToggleBg,
              ),
              _ArcCaption(currentG: currentG, goalG: goalG),
            ],
          ),
        ),
      );
    }

    if (!animate) return frame(progress);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => frame(animated),
    );
  }
}

final class _ArcCaption extends StatelessWidget {
  const _ArcCaption({required this.currentG, this.goalG});

  final int currentG;
  final int? goalG;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$currentG', style: AppTextStyles.proteinHero),
        Text(
          goalG == null
              ? 'protein_page.goal_unknown'.tr()
              : 'protein_page.goal_fmt'.tr(args: ['$goalG']),
          style: AppTextStyles.proteinGoal,
        ),
      ],
    );
  }
}

final class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});

  final NutritionMeal meal;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final time = DateFormat.Hm(locale).format(meal.eatenAt);
    final kind = meal.slot ?? meal.kind;
    final kindKey = kind == null ? null : 'protein_page.kind_$kind';
    final kindLabel = kindKey == null
        ? null
        : () {
            final t = kindKey.tr();
            return t == kindKey ? 'protein_page.kind_other'.tr() : t;
          }();
    final meta = kindLabel == null ? time : '$time · $kindLabel';
    final title = meal.title.isEmpty
        ? 'protein_page.meal_untitled'.tr()
        : meal.title;

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
              child: meal.photoUrl != null
                  ? Image.network(
                      meal.photoUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => AppImages.grilledSalad.image(
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    )
                  : AppImages.grilledSalad.image(
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.proteinMealTitle,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meta,
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
                  'protein_page.grams'.tr(args: ['${meal.proteinG.round()}']),
                  style: AppTextStyles.proteinMealGrams,
                ),
                Text(
                  '${meal.kcal} ${'calories_page.kcal'.tr()}',
                  style: AppTextStyles.proteinMealKcal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _WeekBar extends StatelessWidget {
  const _WeekBar({
    required this.labelKey,
    required this.grams,
    required this.maxGrams,
    required this.animate,
  });

  final String labelKey;
  final int grams;
  final double maxGrams;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final target = maxGrams <= 0 ? 0.0 : (grams / maxGrams).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(labelKey.tr(), style: AppTextStyles.sleepDayLabel),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const reserve = 52.0;
              final barMax = math.max(0.0, constraints.maxWidth - reserve);

              Widget bar(double t) {
                return Row(
                  children: [
                    SizedBox(
                      width: barMax * t,
                      height: 14,
                      child: t <= 0
                          ? null
                          : const DecoratedBox(
                              decoration: BoxDecoration(
                                color: ColorName.colorPremiumGradientStart,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(999),
                                ),
                              ),
                            ),
                    ),
                    const Spacer(),
                    Text(
                      'protein_page.grams'.tr(args: ['$grams']),
                      style: AppTextStyles.sleepDayLabel,
                    ),
                  ],
                );
              }

              if (!animate) return bar(target);
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: target),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, animated, _) => bar(animated),
              );
            },
          ),
        ),
      ],
    );
  }
}

final class _CalculateBar extends StatelessWidget {
  const _CalculateBar({required this.bottomInset, required this.onCalculate});

  final double bottomInset;
  final Future<void> Function() onCalculate;

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
          onPressed: onCalculate,
          decoration: AppButtonDecoration.hungerResult(),
        ),
      ),
    );
  }
}
