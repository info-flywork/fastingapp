import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/steps_view_mixin.dart';

const _kStepsHeaderHeight = 56.0;

/// Adım takip detay — turuncu tema, günlük ilerleme, istatistikler,
/// haftalık grafik.
final class StepsView extends StatefulWidget {
  const StepsView({
    this.initialSteps = 1000,
    this.dailyGoalSteps = 8000,
    super.key,
  });

  final int initialSteps;
  final int dailyGoalSteps;

  @override
  State<StepsView> createState() => _StepsViewState();
}

class _StepsViewState extends State<StepsView>
    with SingleTickerProviderStateMixin, StepsViewMixin {
  @override
  void initState() {
    super.initState();
    initStepsControllers();
  }

  @override
  void dispose() {
    disposeStepsControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorWhite,
        body: AnimatedBuilder(
          animation: progressController,
          builder: (context, _) {
            final progress = progressAnimation.value.clamp(0.0, 1.0);

            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [ColorName.colorWhite, ColorName.colorStepsPageFade],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(
                      height: _kStepsHeaderHeight,
                      width: double.infinity,
                      child: _StepsHeader(),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 24),
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          children: [
                            _StepsRing(
                              progress: progress,
                              currentSteps: currentSteps,
                              goalReached: goalReached,
                            ),
                            const SizedBox(height: 12),
                            _StepsGoalRow(
                              dailyGoalSteps: dailyGoalSteps,
                              goalReached: goalReached,
                            ),
                            const SizedBox(height: 28),
                            _StepsStatsRow(
                              calories: caloriesKcal,
                              distanceKm: distanceKm,
                              durationMin: durationMin,
                            ),
                            const SizedBox(height: 28),
                            _StepsWeeklyChart(
                              values: weeklySteps,
                              goal: dailyGoalSteps,
                              todayIndex: todayWeekIndex,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

final class _StepsHeader extends StatelessWidget {
  const _StepsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _CircleIconButton(
            onTap: () => context.pop(),
            child: Assets.icons.solarAltArrowUpLineDuotone.svg(
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                ColorName.colorTitle,
                BlendMode.srcIn,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chevron_left_rounded,
                  color: ColorName.colorTitle.withValues(alpha: 0.35),
                ),
                Text('steps_page.today'.tr(), style: AppTextStyles.stepsToday),
                Icon(
                  Icons.chevron_right_rounded,
                  color: ColorName.colorTitle.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

final class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorWhite,
      shape: const CircleBorder(),
      shadowColor: ColorName.colorBlack.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
      ),
    );
  }
}

final class _StepsRing extends StatelessWidget {
  const _StepsRing({
    required this.progress,
    required this.currentSteps,
    required this.goalReached,
  });

  final double progress;
  final int currentSteps;
  final bool goalReached;

  static const _size = 220.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(_size, _size),
            painter: _StepsRingPainter(progress: progress),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (goalReached) ...[
                Text(
                  'steps_page.goal_achieved'.tr(),
                  style: AppTextStyles.stepsGoalAchieved,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
              ] else ...[
                AppImages.steps.image(
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 4),
              ],
              Text('$currentSteps', style: AppTextStyles.stepsHeroAmount),
              Text('steps_page.unit'.tr(), style: AppTextStyles.stepsUnit),
            ],
          ),
        ],
      ),
    );
  }
}

final class _StepsRingPainter extends CustomPainter {
  _StepsRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.width * 0.085;
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = ColorName.colorStepsRingBg
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0.001) return;

    final fill = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          ColorName.colorStepsFill,
          ColorName.colorStepsAction,
          ColorName.colorStreakGradientEnd,
        ],
        stops: [0.0, 0.55, 1.0],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fill);
  }

  @override
  bool shouldRepaint(covariant _StepsRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

final class _StepsGoalRow extends StatelessWidget {
  const _StepsGoalRow({
    required this.dailyGoalSteps,
    required this.goalReached,
  });

  final int dailyGoalSteps;
  final bool goalReached;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'steps_page.daily_target_prefix'.tr(),
                  style: AppTextStyles.stepsDailyTarget,
                ),
                TextSpan(
                  text: '$dailyGoalSteps',
                  style: AppTextStyles.stepsDailyTargetBold,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (goalReached)
            AppImages.solarVerifiedCheckBold.image(width: 22, height: 22)
          else
            Icon(
              Icons.flag_rounded,
              size: 20,
              color: ColorName.colorStepsAction.withValues(alpha: 0.85),
            ),
        ],
      ),
    );
  }
}

final class _StepsStatsRow extends StatelessWidget {
  const _StepsStatsRow({
    required this.calories,
    required this.distanceKm,
    required this.durationMin,
  });

  final int calories;
  final String distanceKm;
  final int durationMin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            labelKey: 'steps_page.calories',
            value: 'steps_page.calories_value'.tr(args: ['$calories']),
            icon: Icons.local_fire_department_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            labelKey: 'steps_page.distance',
            value: 'steps_page.distance_value'.tr(args: [distanceKm]),
            icon: Icons.straighten_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            labelKey: 'steps_page.duration',
            value: 'steps_page.duration_value'.tr(args: ['$durationMin']),
            icon: Icons.timer_outlined,
          ),
        ),
      ],
    );
  }
}

final class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.labelKey,
    required this.value,
    required this.icon,
  });

  final String labelKey;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: ColorName.colorStepsAction),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.stepsStatValue),
          const SizedBox(height: 2),
          Text(labelKey.tr(), style: AppTextStyles.stepsStatLabel),
        ],
      ),
    );
  }
}

final class _StepsWeeklyChart extends StatelessWidget {
  const _StepsWeeklyChart({
    required this.values,
    required this.goal,
    required this.todayIndex,
  });

  final List<int> values;
  final int goal;
  final int todayIndex;

  static const _dayKeys = [
    'steps_page.day_mon',
    'steps_page.day_tue',
    'steps_page.day_wed',
    'steps_page.day_thu',
    'steps_page.day_fri',
    'steps_page.day_sat',
    'steps_page.day_sun',
  ];

  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(goal, values.reduce(math.max)).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'steps_page.weekly'.tr(),
            style: AppTextStyles.stepsSectionTitle,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _WeekBar(
                      value: values[i],
                      maxValue: maxValue,
                      labelKey: _dayKeys[i],
                      isToday: i == todayIndex,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _WeekBar extends StatelessWidget {
  const _WeekBar({
    required this.value,
    required this.maxValue,
    required this.labelKey,
    required this.isToday,
  });

  final int value;
  final double maxValue;
  final String labelKey;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.08, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: ratio,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: isToday
                        ? const [
                            ColorName.colorStepsAction,
                            ColorName.colorStepsFill,
                          ]
                        : [
                            ColorName.colorStepsFill.withValues(alpha: 0.35),
                            ColorName.colorStepsFill.withValues(alpha: 0.55),
                          ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          labelKey.tr(),
          style: AppTextStyles.stepsWeekday.copyWith(
            color: isToday
                ? ColorName.colorStepsAction
                : ColorName.colorSubtitle.withValues(alpha: 0.55),
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

final class _StepsControls extends StatelessWidget {
  const _StepsControls({
    required this.addSteps,
    required this.onAdd,
    required this.onRemove,
  });

  final int addSteps;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _StepsActionCircle(
          size: _StepsActionCircle.minusSize,
          onTap: onRemove,
          child: Assets.icons.icRoundMinus.svg(
            width: 40,
            height: 40,
            colorFilter: const ColorFilter.mode(
              ColorName.colorWhite,
              BlendMode.srcIn,
            ),
          ),
        ),
        _StepsActionCircle(
          onTap: onAdd,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Assets.icons.uilPlus.svg(
                width: 40,
                height: 40,
                colorFilter: const ColorFilter.mode(
                  ColorName.colorWhite,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'steps_page.add_amount'.tr(args: ['$addSteps']),
                style: AppTextStyles.stepsAddLabel,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(
          width: _StepsActionCircle.minusSize,
          height: _StepsActionCircle.minusSize,
          child: Center(
            child: AppImages.steps.image(
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

final class _StepsActionCircle extends StatelessWidget {
  const _StepsActionCircle({
    required this.onTap,
    required this.child,
    this.size = plusSize,
  });

  static const plusSize = 90.0;
  static const minusSize = 56.0;
  static const _padding = EdgeInsets.fromLTRB(10, 14, 10, 14);

  final VoidCallback onTap;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorName.colorStepsAction,
            border: Border.all(
              color: ColorName.colorWhite.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: ColorName.colorWhite.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 4),
                blurStyle: BlurStyle.inner,
              ),
            ],
          ),
          child: Padding(
            padding: _padding,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
