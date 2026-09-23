import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/horseshoe_arc.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Profil → Uyku. Yarım daire, haftalık bar ve program kartları.
final class SleepView extends StatelessWidget {
  const SleepView({super.key});

  static const _hours = <double>[8, 6.4, 7, 7, 7, 7.1, 8.6];

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
                child: _SleepHeader(),
              ),
              Expanded(
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 24),
                  children: [
                    const _SleepArc(),
                    const SizedBox(height: 8),
                    const _BoundRow(),
                    const SizedBox(height: 20),
                    const _HourAxis(),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _hours.length; i++) ...[
                      _SleepDayBar(labelKey: _dayKeys[i], hours: _hours[i]),
                      if (i != _hours.length - 1) const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'sleep_page.schedule'.tr(),
                      style: AppTextStyles.sleepSectionTitle,
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(
                          child: _ScheduleCard(
                            icon: _ScheduleIcon.bedtime,
                            valueKey: 'sleep_page.bedtime_value',
                            labelKey: 'sleep_page.bedtime',
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _ScheduleCard(
                            icon: _ScheduleIcon.wake,
                            valueKey: 'sleep_page.wakeup_value',
                            labelKey: 'sleep_page.wakeup',
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _ScheduleCard(
                            icon: _ScheduleIcon.goal,
                            valueKey: 'sleep_page.goal_value',
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
  const _SleepArc();

  static const _progress = 0.78;

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
      child: const Padding(
        padding: EdgeInsets.only(top: 36),
        child: _ArcCaption(),
      ),
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
        Text('sleep_page.last_night'.tr(), style: AppTextStyles.sleepCaption),
        const SizedBox(height: 2),
        Text('sleep_page.duration'.tr(), style: AppTextStyles.sleepDuration),
      ],
    );
  }
}

final class _BoundRow extends StatelessWidget {
  const _BoundRow();

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
              Text(
                'sleep_page.bedtime_value'.tr(),
                style: AppTextStyles.sleepBoundValue,
              ),
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
              Text(
                'sleep_page.wake_up_value'.tr(),
                style: AppTextStyles.sleepBoundValue,
              ),
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
    required this.valueKey,
    required this.labelKey,
  });

  final _ScheduleIcon icon;
  final String valueKey;
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
              valueKey.tr(),
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

  AssetGenImage get _asset => switch (icon) {
    _ScheduleIcon.bedtime => Assets.images.bedtime,
    _ScheduleIcon.wake => Assets.images.wake,
    _ScheduleIcon.goal => Assets.images.goal,
  };
}
