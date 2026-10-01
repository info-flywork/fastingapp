import 'dart:math' as math;
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Mochi World tab — ada, ilerleme ve bölgeler.
final class MochiWorldView extends StatefulWidget {
  const MochiWorldView({super.key});

  @override
  State<MochiWorldView> createState() => _MochiWorldViewState();
}

class _MochiWorldViewState extends State<MochiWorldView> {
  static final _zones = <_Zone>[
    _Zone(
      id: _ZoneId.forest,
      icon: Assets.images.forest,
      titleKey: 'mochi_world.forest',
      progressKey: 'mochi_world.forest_progress',
      current: 3,
      goal: 10,
    ),
    _Zone(
      id: _ZoneId.lake,
      icon: Assets.images.lake,
      titleKey: 'mochi_world.lake',
      progressKey: 'mochi_world.lake_progress',
      current: 2,
      goal: 7,
    ),
    _Zone(
      id: _ZoneId.summit,
      icon: Assets.images.summit,
      titleKey: 'mochi_world.summit',
      progressKey: 'mochi_world.summit_progress',
      current: 0,
      goal: 2,
    ),
    _Zone(
      id: _ZoneId.garden,
      icon: Assets.images.garden,
      titleKey: 'mochi_world.garden',
      progressKey: 'mochi_world.garden_progress',
      current: 3,
      goal: 10,
    ),
  ];

  _ZoneId _selected = _ZoneId.forest;

  _Zone get _active => _zones.firstWhere((z) => z.id == _selected);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFB8D9F0),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Assets.images.mochiWorlds.image(
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: top + 8,
                bottom: MediaQuery.paddingOf(context).bottom + 16,
              ),
              child: Column(
                children: [
                  const _Header(),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _WeekCard(),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _WorldProgressCard(progress: 0.12),
                  ),
                  Expanded(
                    child: Align(
                      alignment: const Alignment(-0.72, -0.8),
                      child: Assets.images.mascotHiWithout.image(
                        height: 155,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        for (var i = 0; i < _zones.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _ZoneCard(
                              zone: _zones[i],
                              selected: _zones[i].id == _selected,
                              onTap: () =>
                                  setState(() => _selected = _zones[i].id),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ZoneProgressCard(zone: _active),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ZoneId { forest, lake, summit, garden }

final class _Zone {
  const _Zone({
    required this.id,
    required this.icon,
    required this.titleKey,
    required this.progressKey,
    required this.current,
    required this.goal,
  });

  final _ZoneId id;
  final AssetGenImage icon;
  final String titleKey;
  final String progressKey;
  final int current;
  final int goal;

  double get ratio => goal <= 0 ? 0 : (current / goal).clamp(0.0, 1.0);
}

final class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _CircleBackButton(onTap: () => context.go(RoutePaths.home.path)),
          Expanded(
            child: Text(
              'mochi_world.title'.tr(),
              textAlign: TextAlign.center,
              style: _title,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: ColorName.colorWhite,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text('mochi_world.level'.tr(args: ['1']), style: _level),
            ),
          ),
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Transform.rotate(
              angle: math.pi,
              child: Assets.icons.solarAltArrowUpLineDuotoneRight.svg(
                width: 20,
                height: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.radius = 16,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ColorName.colorBodyPageBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

final class _WeekCard extends StatelessWidget {
  const _WeekCard();

  static const _dayKeys = [
    'home.week_mon',
    'home.week_tue',
    'home.week_wed',
    'home.week_thu',
    'home.week_fri',
    'home.week_sat',
    'home.week_sun',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final selectedIndex = today.weekday - 1;

    return _GlassCard(
      radius: 12,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _WeekDay(
                dayKey: _dayKeys[i],
                date: monday.add(Duration(days: i)),
                selected: i == selectedIndex,
                hours: i == selectedIndex ? 10 : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

final class _WeekDay extends StatelessWidget {
  const _WeekDay({
    required this.dayKey,
    required this.date,
    required this.selected,
    this.hours,
  });

  final String dayKey;
  final DateTime date;
  final bool selected;
  final int? hours;

  @override
  Widget build(BuildContext context) {
    final dayColor = selected
        ? ColorName.colorBrandStrong
        : ColorName.colorSubtitle.withValues(alpha: 0.5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          dayKey.tr(),
          style: AppTextStyles.homeWeekDay.copyWith(color: dayColor),
        ),
        const SizedBox(height: 2),
        Text(
          '${date.day}',
          style: AppTextStyles.homeWeekDate.copyWith(
            color: selected
                ? ColorName.colorTitle
                : ColorName.colorSubtitle.withValues(alpha: 0.45),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        DecoratedBox(
          decoration: BoxDecoration(
            color: hours != null
                ? ColorName.colorMealPositive
                : ColorName.colorWhite.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              hours != null ? 'home.week_hours'.tr(args: ['$hours']) : '—',
              style: _chip.copyWith(
                color: hours != null
                    ? ColorName.colorWhite
                    : ColorName.colorSubtitle.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final class _WorldProgressCard extends StatelessWidget {
  const _WorldProgressCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Text('mochi_world.world_progress'.tr(), style: _sectionTitle),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: _sectionTitle.copyWith(color: ColorName.colorStepsFill),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ProgressBar(
            value: progress,
            fill: ColorName.colorStepsFill,
            track: ColorName.colorWhite,
          ),
        ],
      ),
    );
  }
}

final class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.zone,
    required this.selected,
    required this.onTap,
  });

  final _Zone zone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ColorName.colorWhite.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? ColorName.colorWhite : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            zone.icon.image(height: 40, fit: BoxFit.contain),
            const SizedBox(height: 10),
            Text(
              zone.titleKey.tr(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _zoneTitle,
            ),
            const SizedBox(height: 2),
            Text(
              zone.progressKey.tr(args: ['${zone.current}', '${zone.goal}']),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _zoneMeta,
            ),
          ],
        ),
      ),
    );
  }
}

final class _ZoneProgressCard extends StatelessWidget {
  const _ZoneProgressCard({required this.zone});

  final _Zone zone;

  static const _fill = Color(0xFFA7CC65);
  static const _duration = Duration(milliseconds: 420);

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: _duration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    key: ValueKey('title-${zone.id}'),
                    child: Text(
                      zone.titleKey.tr(),
                      textAlign: TextAlign.left,
                      style: _sectionTitle,
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: _duration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                child: Text(
                  '${zone.current}/${zone.goal}',
                  key: ValueKey('count-${zone.id}'),
                  textAlign: TextAlign.right,
                  style: _sectionTitle.copyWith(color: _fill),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ProgressBar(
            value: zone.ratio,
            fill: _fill,
            track: ColorName.colorWhite,
          ),
        ],
      ),
    );
  }
}

final class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.fill,
    required this.track,
    this.duration = const Duration(milliseconds: 420),
  });

  final double value;
  final Color fill;
  final Color track;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 7,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99999),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: track),
            TweenAnimationBuilder<double>(
              tween: Tween(end: value.clamp(0.0, 1.0)),
              duration: duration,
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) {
                return FractionallySizedBox(
                  widthFactor: animated,
                  alignment: Alignment.centerLeft,
                  child: ColoredBox(color: fill),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

const _title = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 20,
  height: 1.2,
  letterSpacing: -0.5,
  color: ColorName.colorTitle,
);

const _level = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 14,
  height: 20 / 14,
  letterSpacing: -0.5,
  color: ColorName.colorTitle,
);

const _sectionTitle = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 14,
  height: 20 / 14,
  letterSpacing: -0.5,
  color: ColorName.colorTitle,
);

const _chip = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 11,
  height: 1,
);

const _zoneTitle = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 14,
  height: 20 / 14,
  letterSpacing: -0.5,
  color: ColorName.colorTitle,
);

final _zoneMeta = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 13,
  height: 16 / 13,
  letterSpacing: 13 * -0.015,
  color: ColorName.colorSubtitle.withValues(alpha: 0.6),
);
