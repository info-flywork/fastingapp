import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/bottom_navigation_bar/'
    'app_bottom_nav.dart';
import 'package:fastingapp/core/widgets/horseshoe_arc.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_plan_sheet.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_start_sheet.dart';
import 'package:fastingapp/presentation/home/view/home_view.dart';
import 'package:fastingapp/presentation/plans/plans_catalog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Oruç sekmesi — öğün zamanı, horseshoe ve aksiyonlar.
final class FastingView extends StatefulWidget {
  const FastingView({super.key});

  @override
  State<FastingView> createState() => _FastingViewState();
}

class _FastingViewState extends State<FastingView> {
  var _mealSelected = true;
  PlansCardData _plan = PlansCatalog.beginnerRow1.first;
  DateTime? _started;

  Future<void> _pickPlan() async {
    final picked = await showModalBottomSheet<PlansCardData>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FastingPlanSheet(selected: _plan),
    );
    if (!mounted || picked == null) return;
    setState(() => _plan = picked);
  }

  Future<void> _pickStart() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          FastingStartSheet(initial: _started ?? DateTime.now()),
    );
    if (!mounted || picked == null) return;
    setState(() => _started = picked);
  }

  int _planHours(String title) {
    final head = title.split('-').first.trim();
    return int.tryParse(head) ?? 16;
  }

  String _boundLabel(DateTime value) {
    final locale = context.locale.toString();
    final day = DateUtils.isSameDay(value, DateTime.now())
        ? 'fasting_page.start_sheet_today'.tr()
        : DateFormat('d MMM', locale).format(value);
    final clock = context.locale.languageCode == 'en'
        ? DateFormat('h:mm a', locale).format(value)
        : DateFormat('HH:mm', locale).format(value);
    return '$day, $clock';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorName.colorProfileBack,
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppBottomNav.barClearance),
        children: [
          HomeTopBar(
            streakDays: 3,
            isPremium: false,
            onPremiumTapped: () {},
            onChatTapped: () => context.pushNamed(RoutePaths.chat.name),
          ),
          const SizedBox(height: 16),
          _ActionRow(
            mealSelected: _mealSelected,
            onBodyTap: () => setState(() => _mealSelected = false),
            onMealTap: () => setState(() => _mealSelected = true),
          ),
          const SizedBox(height: 20),
          Text(
            'fasting_page.meal_time'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.fastingMealTitle,
          ),
          const SizedBox(height: 12),
          const _BreakFastCard(),
          const SizedBox(height: 8),
          _FastingArc(planTitle: _plan.title, onEditPlan: _pickPlan),
          const SizedBox(height: 16),
          _FastingActions(
            planTitle: _plan.title,
            started: _started == null ? null : _boundLabel(_started!),
            ends: _started == null
                ? null
                : _boundLabel(
                    _started!.add(Duration(hours: _planHours(_plan.title))),
                  ),
            onStart: _pickStart,
          ),
          // Kartların 12px üst boşluğuyla birlikte aralık 16.
          const SizedBox(height: 4),
          const HomeChallengeCard(),
          const SizedBox(height: 4),
          HomeMetricCards(
            onWaterTapped: () => context.pushNamed(RoutePaths.water.name),
            onStepsTapped: () => context.pushNamed(RoutePaths.steps.name),
          ),
          const SizedBox(height: 4),
          HomeWeightCard(
            onTap: () => context.pushNamed(RoutePaths.bodyHistory.name),
            onEditTap: () {
              AppDialogs.instance.showEditWeight(
                context,
                initialWeightKg: HomeWeightCard.currentKg,
              );
            },
          ),
          const SizedBox(height: 4),
          HomeHungerTrackerCard(
            onTap: () => context.pushNamed(RoutePaths.hungerTracker.name),
          ),
        ],
      ),
    );
  }
}

final class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.mealSelected,
    required this.onBodyTap,
    required this.onMealTap,
  });

  final bool mealSelected;
  final VoidCallback onBodyTap;
  final VoidCallback onMealTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _CircleButton(
            child: Assets.icons.solarSquareShareLineLineDuotone.svg(),
          ),
          const Spacer(),
          _ModeToggle(
            mealSelected: mealSelected,
            onBodyTap: onBodyTap,
            onMealTap: onMealTap,
          ),
          const Spacer(),
          _CircleButton(
            onTap: () => context.pushNamed(RoutePaths.water.name),
            child: Transform.scale(
              scale: 1.45,
              child: Assets.images.water.image(
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.05),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 40, height: 40, child: Center(child: child)),
        ),
      ),
    );
  }
}

final class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.mealSelected,
    required this.onBodyTap,
    required this.onMealTap,
  });

  final bool mealSelected;
  final VoidCallback onBodyTap;
  final VoidCallback onMealTap;

  static const _segmentWidth = 44.0;
  static const _gap = 8.0;
  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorUnitToggleBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.12),
            offset: const Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          width: _segmentWidth * 2 + _gap,
          height: 32,
          child: Stack(
            children: [
              IgnorePointer(
                child: AnimatedAlign(
                  duration: _duration,
                  curve: Curves.easeOutCubic,
                  alignment: mealSelected
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: const _SelectedPill(width: _segmentWidth),
                ),
              ),
              Row(
                children: [
                  _ModeSegment(
                    onTap: onBodyTap,
                    child: Transform.scale(
                      scale: 1.25,
                      child: Assets.images.human.image(
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: _gap),
                  _ModeSegment(
                    onTap: onMealTap,
                    child: Assets.images.forkClosest.image(
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SelectedPill extends StatelessWidget {
  const _SelectedPill({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.05),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: SizedBox(width: width, height: 32),
    );
  }
}

final class _ModeSegment extends StatelessWidget {
  const _ModeSegment({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _ModeToggle._segmentWidth,
        height: 32,
        child: Center(child: child),
      ),
    );
  }
}

final class _BreakFastCard extends StatelessWidget {
  const _BreakFastCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.pushNamed(RoutePaths.eatingWindow.name),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Assets.images.breakYourFast.image(
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'fasting_page.break_title'.tr(),
                        style: AppTextStyles.fastingBreakTitle,
                      ),
                      Text(
                        'fasting_page.break_body'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.fastingBreakBody,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Assets.icons.solarAltArrowUpLineDuotoneRight.svg(
                  width: 20,
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _FastingArc extends StatelessWidget {
  const _FastingArc({required this.planTitle, required this.onEditPlan});

  final String planTitle;
  final VoidCallback onEditPlan;

  static const _progress = 0.10;
  static const _arcTop = 18.0;
  static const _marker = 54.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: _progress),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final arcSize = Size(
              constraints.maxWidth,
              HorseshoeArc.diameterDefault + 5,
            );
            final arcStart = _pointOnArc(arcSize, 0);
            final breakFast = _pointOnArc(arcSize, progress);
            final nourish = _pointOnArc(arcSize, 0.5);
            final nextFast = _pointOnArc(arcSize, 1);
            final height = _arcTop + arcStart.dy + _marker / 2 + 6;

            return SizedBox(
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: _arcTop,
                    left: 0,
                    right: 0,
                    height: arcSize.height,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        HorseshoeArc(
                          progress: progress,
                          minProgress: 0,
                          progressColor: ColorName.colorPlanFasting,
                          trackColor: ColorName.colorUnitToggleBg,
                        ),
                        child!,
                        _ArcMarker(
                          center: breakFast,
                          image: Assets.images.breakYourFast,
                        ),
                        _ArcMarker(
                          center: nourish,
                          image: Assets.images.darkNorusih,
                          scale: 1.35,
                        ),
                        _ArcMarker(
                          center: nextFast,
                          image: Assets.images.darkFast,
                          scale: 1.25,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: _ArcCaption(planTitle: planTitle, onEditPlan: onEditPlan),
    );
  }
}

Offset _pointOnArc(Size size, double t) {
  final radius = (math.min(size.width, size.height) - HorseshoeArc.stroke) / 2;
  final angle =
      HorseshoeArc.startRad + HorseshoeArc.sweepDegrees * math.pi / 180 * t;
  return Offset(
    size.width / 2 + radius * math.cos(angle),
    size.height / 2 + radius * math.sin(angle),
  );
}

final class _ArcCaption extends StatelessWidget {
  const _ArcCaption({required this.planTitle, required this.onEditPlan});

  final String planTitle;
  final VoidCallback onEditPlan;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'fasting_page.time_passed'.tr(args: const ['10']),
          style: AppTextStyles.fastingTimePassed,
        ),
        Text('01:44:14', style: AppTextStyles.fastingTimer),
        const SizedBox(height: 8),
        _PlanChip(title: planTitle, onEditPlan: onEditPlan),
      ],
    );
  }
}

final class _PlanChip extends StatelessWidget {
  const _PlanChip({required this.title, required this.onEditPlan});

  final String title;
  final VoidCallback onEditPlan;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 3, 7, 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppTextStyles.fastingPlanChip),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onEditPlan,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: _PenIcon(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PenIcon extends StatelessWidget {
  const _PenIcon();

  @override
  Widget build(BuildContext context) {
    return Assets.images.solarPenBold1.image(
      width: 18,
      height: 18,
      fit: BoxFit.contain,
    );
  }
}

final class _ArcMarker extends StatelessWidget {
  const _ArcMarker({required this.center, required this.image, this.scale = 1});

  final Offset center;
  final AssetGenImage image;
  final double scale;

  @override
  Widget build(BuildContext context) {
    const size = _FastingArc._marker;
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColorName.colorWhite,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: ColorName.colorBlack.withValues(alpha: 0.05),
              offset: const Offset(0, 1.3),
              blurRadius: 5.4,
            ),
            BoxShadow(
              color: ColorName.colorBlack.withValues(alpha: 0.1),
              offset: const Offset(0, 1.3),
              blurRadius: 5.4,
            ),
          ],
        ),
        child: ClipOval(
          child: SizedBox(
            width: size,
            height: size,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Transform.scale(
                scale: scale,
                child: image.image(fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _FastingActions extends StatelessWidget {
  const _FastingActions({
    required this.planTitle,
    required this.started,
    required this.ends,
    required this.onStart,
  });

  final String planTitle;
  final String? started;
  final String? ends;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _TimeRow(started: started, ends: ends),
          const SizedBox(height: 20),
          AppButton(
            label: 'fasting_page.start_cta'.tr(args: [planTitle]),
            onPressed: onStart,
            showIcon: false,
            decoration: AppButtonDecoration.fastingStart(),
          ),
        ],
      ),
    );
  }
}

final class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.started, required this.ends});

  final String? started;
  final String? ends;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'fasting_page.started_label'.tr(),
              style: AppTextStyles.fastingBoundLabel,
            ),
            Text(
              started ?? 'fasting_page.started_value'.tr(),
              style: AppTextStyles.fastingBoundValue,
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'fasting_page.ends_label'.tr(),
              style: AppTextStyles.fastingBoundLabel,
            ),
            Text(
              ends ?? 'fasting_page.ends_value'.tr(),
              style: AppTextStyles.fastingBoundValue,
            ),
          ],
        ),
      ],
    );
  }
}
