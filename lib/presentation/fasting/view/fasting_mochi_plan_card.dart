import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/horseshoe_arc.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Fasting sayfası altı — Mochi'nin bugünkü plan kartı.
final class FastingMochiPlanCard extends StatelessWidget {
  const FastingMochiPlanCard({
    required this.fastHours,
    required this.eatHours,
    required this.startedLabel,
    required this.endsLabel,
    required this.onStart,
    super.key,
  });

  final int fastHours;
  final int eatHours;
  final String startedLabel;
  final String endsLabel;
  final VoidCallback onStart;

  static const _arcDiameter = 280.0;

  @override
  Widget build(BuildContext context) {
    final total = (fastHours + eatHours).clamp(1, 48);
    final progress = fastHours / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Header(),
          const SizedBox(height: 16),
          _ArcBlock(
            progress: progress,
            fastHours: fastHours,
            eatHours: eatHours,
          ),
          _TimeRow(started: startedLabel, ends: endsLabel),
          const SizedBox(height: 16),
          const _InsightBox(),
          const SizedBox(height: 16),
          AppButton(
            label: 'fasting_page.mochi_plan_start'.tr(),
            onPressed: onStart,
            showIcon: false,
            decoration: AppButtonDecoration.hungerResult(),
          ),
        ],
      ),
    );
  }
}

/// Figma Frame 1597878668 — beyaz container title/subtitle;
/// büyütülmüş mascot üst/alttan clip edilir.
final class _Header extends StatelessWidget {
  const _Header();

  static const _mascotSize = 80.0;
  static const _radius = 16.0;
  static const _pad = 12.0;
  static const _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: ColoredBox(
        color: ColorName.colorWhite,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _pad + _mascotSize * 0.72 + _gap,
                _pad,
                _pad,
                _pad,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'fasting_page.mochi_plan_title'.tr(),
                    style: AppTextStyles.fastingMochiPlanTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'fasting_page.mochi_plan_subtitle'.tr(),
                    style: AppTextStyles.fastingMochiPlanSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Positioned(
              left: _pad * 0.5,
              top: 0,
              bottom: 0,
              width: _mascotSize,
              child: Center(
                child: Transform.scale(
                  scale: 1.2,
                  child: AppImages.mascotHiWithout.image(
                    width: _mascotSize,
                    height: _mascotSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ArcBlock extends StatelessWidget {
  const _ArcBlock({
    required this.progress,
    required this.fastHours,
    required this.eatHours,
  });

  final double progress;
  final int fastHours;
  final int eatHours;

  @override
  Widget build(BuildContext context) {
    const d = FastingMochiPlanCard._arcDiameter;
    // Kalın stroke (stroke+4) üst/yanlardan kesilmesin.
    const inset = 12.0;

    return SizedBox(
      height: d * 0.82 + inset,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: inset - 10,
            left: 0,
            right: 0,
            height: d + 5,
            child: Stack(
              children: [
                HorseshoeArc(
                  progress: progress,
                  diameter: d,
                  trackColor: ColorName.colorUnitToggleBg,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'fasting_page.mochi_plan_fasting'.tr(),
                  style: AppTextStyles.fastingMochiPlanArcLabel,
                ),
                Text(
                  'fasting_page.mochi_plan_duration'.tr(
                    args: ['$fastHours', '00'],
                  ),
                  style: AppTextStyles.fastingMochiPlanDuration,
                ),
                const SizedBox(height: 4),
                _EatingChip(eatHours: eatHours),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma Frame 48096390 — hug, radius 21.42, pad 10.71 / 2.68, #FFFFFF.
final class _EatingChip extends StatelessWidget {
  const _EatingChip({required this.eatHours});

  final int eatHours;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(21.42),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.71, vertical: 2.68),
        child: Text(
          'fasting_page.mochi_plan_eating'.tr(args: ['$eatHours']),
          style: AppTextStyles.fastingMochiPlanEating,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

final class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.started, required this.ends});

  final String started;
  final String ends;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'fasting_page.started_label'.tr(),
                style: AppTextStyles.fastingBoundLabel,
              ),
              Text(started, style: AppTextStyles.fastingBoundValue),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'fasting_page.ends_label'.tr(),
                style: AppTextStyles.fastingBoundLabel,
              ),
              Text(ends, style: AppTextStyles.fastingBoundValue),
            ],
          ),
        ),
      ],
    );
  }
}

/// Figma Frame 1597878705 — pad 12, radius 16.
final class _InsightBox extends StatelessWidget {
  const _InsightBox();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorName.colorFlipClock),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'fasting_page.mochi_plan_insight'.tr(),
          style: AppTextStyles.fastingMochiPlanInsight,
        ),
      ),
    );
  }
}
