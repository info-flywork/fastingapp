import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/horseshoe_arc.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Profil → Uyku. Yarım daire, haftalık bar ve program kartları.
final class SleepView extends StatefulWidget {
  const SleepView({super.key});

  @override
  State<SleepView> createState() => _SleepViewState();
}

final class _SleepViewState extends State<SleepView> {
  SleepSummary? _summary;

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
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final summary = await getIt<TrackersRepository>().getSleepSummary();
      if (mounted) setState(() => _summary = summary);
    } on Object {
      // Boş özet — UI sıfır değerleri gösterir
    }
  }

  static String _formatMinutes(int? minutes) {
    if (minutes == null || minutes <= 0) return '—';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static String _goalHours(int goalMin) {
    final h = goalMin / 60;
    return '${h.toStringAsFixed(1)}h';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final summary = _summary;
    final progress = summary?.progress ?? 0;
    final lastNight = _formatMinutes(summary?.lastNightMinutes);
    final weekHours = summary?.weekMinutes.isNotEmpty == true
        ? summary!.weekMinutes.map((m) => m / 60).toList()
        : List<double>.filled(7, 0);
    final bedtime = summary?.bedtime ?? '—';
    final wakeTime = summary?.wakeTime ?? '—';
    final goalText = summary != null ? _goalHours(summary.goalMin) : '—';

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
                child: _SleepHeader(),
              ),
              Expanded(
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 24),
                  children: [
                    _SleepArc(
                      progress: progress.clamp(0.0, 1.0),
                      durationText: lastNight,
                    ),
                    const SizedBox(height: 8),
                    _BoundRow(bedtime: bedtime, wakeTime: wakeTime),
                    const SizedBox(height: 20),
                    const _HourAxis(),
                    const SizedBox(height: 8),
                    for (var i = 0; i < weekHours.length; i++) ...[
                      _SleepDayBar(
                        labelKey: _dayKeys[i],
                        hours: weekHours[i],
                      ),
                      if (i != weekHours.length - 1) const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'sleep_page.schedule'.tr(),
                      style: AppTextStyles.sleepSectionTitle,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ScheduleCard(
                            icon: _ScheduleIcon.bedtime,
                            valueText: bedtime,
                            labelKey: 'sleep_page.bedtime',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ScheduleCard(
                            icon: _ScheduleIcon.wake,
                            valueText: wakeTime,
                            labelKey: 'sleep_page.wakeup',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ScheduleCard(
                            icon: _ScheduleIcon.goal,
                            valueText: goalText,
                            labelKey: 'sleep_page.goal',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SleepHeader extends StatelessWidget {
  const _SleepHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _CircleBackButton(onTap: () => context.pop()),
          Expanded(
            child: Text(
              'sleep_page.title'.tr(),
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

final class _SleepArc extends StatelessWidget {
  const _SleepArc({required this.progress, required this.durationText});

  final double progress;
  final String durationText;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
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
      child: Padding(
        padding: const EdgeInsets.only(top: 36),
        child: _ArcCaption(durationText: durationText),
      ),
    );
  }
}

final class _ArcCaption extends StatelessWidget {
  const _ArcCaption({required this.durationText});

  final String durationText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('sleep_page.last_night'.tr(), style: AppTextStyles.sleepCaption),
        const SizedBox(height: 2),
        Text(durationText, style: AppTextStyles.sleepDuration),
      ],
    );
  }
}

final class _BoundRow extends StatelessWidget {
  const _BoundRow({required this.bedtime, required this.wakeTime});

  final String bedtime;
  final String wakeTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'sleep_page.bedtime'.tr(),
                style: AppTextStyles.sleepBoundLabel,
              ),
              Text(bedtime, style: AppTextStyles.sleepBoundValue),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'sleep_page.wake_up'.tr(),
                style: AppTextStyles.sleepBoundLabel,
              ),
              Text(wakeTime, style: AppTextStyles.sleepBoundValue),
            ],
          ),
        ),
      ],
    );
  }
}

final class _HourAxis extends StatelessWidget {
  const _HourAxis();

  static const _labels = ['0h', '6h', '12h', '18h', '24h'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final label in _labels)
            Text(label, style: AppTextStyles.sleepAxisLabel),
        ],
      ),
    );
  }
}

final class _SleepDayBar extends StatelessWidget {
  const _SleepDayBar({required this.labelKey, required this.hours});

  final String labelKey;
  final double hours;

  @override
  Widget build(BuildContext context) {
    final progress = (hours / 24).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(labelKey.tr(), style: AppTextStyles.sleepDayLabel),
        ),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 14,
                  child: ColoredBox(
                    color: ColorName.colorJourneyGoalWeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: animated,
                        heightFactor: 1,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: ColorName.colorPremiumGradientStart,
                            borderRadius: BorderRadius.all(
                              Radius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

enum _ScheduleIcon { bedtime, wake, goal }

final class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.icon,
    required this.valueText,
    required this.labelKey,
  });

  final _ScheduleIcon icon;
  final String valueText;
  final String labelKey;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _asset.image(width: 48, height: 48, fit: BoxFit.contain),
            const SizedBox(height: 6),
            Text(
              valueText,
              textAlign: TextAlign.center,
              style: AppTextStyles.sleepCardValue,
            ),
            const SizedBox(height: 4),
            Text(
              labelKey.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.sleepCardLabel,
            ),
          ],
        ),
      ),
    );
  }

  AppImageAsset get _asset => switch (icon) {
    _ScheduleIcon.bedtime => AppImages.bedtime,
    _ScheduleIcon.wake => AppImages.wake,
    _ScheduleIcon.goal => AppImages.goal,
  };
}
