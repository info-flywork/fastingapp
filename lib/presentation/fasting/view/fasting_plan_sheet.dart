import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/plans/plans_catalog.dart';
import 'package:flutter/material.dart';

const _kCardWidth = 251.0;
const _kCardHeight = 144.0;
const _kCardGap = 16.0;
const _kMaxIntensity = 4;
const _kBoltSize = 18.0;

/// Oruç ekranındaki kalemden açılan plan listesi.
final class FastingPlanSheet extends StatelessWidget {
  const FastingPlanSheet({required this.selected, super.key});

  final PlansCardData selected;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.86;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: ColorName.colorWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const DecoratedBox(
              decoration: BoxDecoration(
                color: ColorName.colorPlanArcTrack,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
              child: SizedBox(width: 36, height: 4),
            ),
            const SizedBox(height: 16),
            Text('plans.title'.tr(), style: AppTextStyles.plansPageTitle),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: bottom + 16),
                children: [
                  _Section(
                    titleKey: 'plans.beginner_title',
                    emphasisKey: 'plans.beginner_emphasis',
                    restKey: 'plans.beginner_rest',
                    row1: PlansCatalog.beginnerRow1,
                    row2: PlansCatalog.beginnerRow2,
                    selected: selected,
                  ),
                  const SizedBox(height: 32),
                  _Section(
                    titleKey: 'plans.advanced_title',
                    emphasisKey: 'plans.advanced_emphasis',
                    restKey: 'plans.advanced_rest',
                    row1: PlansCatalog.advancedRow1,
                    row2: PlansCatalog.advancedRow2,
                    selected: selected,
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

final class _Section extends StatelessWidget {
  const _Section({
    required this.titleKey,
    required this.emphasisKey,
    required this.restKey,
    required this.row1,
    required this.row2,
    required this.selected,
  });

  final String titleKey;
  final String emphasisKey;
  final String restKey;
  final List<PlansCardData> row1;
  final List<PlansCardData> row2;
  final PlansCardData selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titleKey.tr(), style: AppTextStyles.plansSectionTitle),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: emphasisKey.tr(),
                      style: AppTextStyles.plansSectionSubtitleEmphasis,
                    ),
                    TextSpan(
                      text: restKey.tr(),
                      style: AppTextStyles.plansSectionSubtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _CardRow(plans: row1, selected: selected),
        const SizedBox(height: _kCardGap),
        _CardRow(plans: row2, selected: selected),
      ],
    );
  }
}

final class _CardRow extends StatelessWidget {
  const _CardRow({required this.plans, required this.selected});

  final List<PlansCardData> plans;
  final PlansCardData selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kCardHeight + 12,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: plans.length,
        separatorBuilder: (_, _) => const SizedBox(width: _kCardGap),
        itemBuilder: (context, index) {
          final plan = plans[index];
          return _PlanCard(plan: plan, selected: selected == plan);
        },
      ),
    );
  }
}

final class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.selected});

  final PlansCardData plan;
  final bool selected;

  static final _shadows = <BoxShadow>[
    BoxShadow(
      color: ColorName.colorBlack.withValues(alpha: 0.10),
      offset: const Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: ColorName.colorBlack.withValues(alpha: 0.09),
      offset: const Offset(0, 6),
      blurRadius: 10,
    ),
    BoxShadow(
      color: ColorName.colorBlack.withValues(alpha: 0.05),
      offset: const Offset(0, 12),
      blurRadius: 16,
    ),
  ];

  /// Kilitli plan: paywall; premium olunca plan seçilir.
  Future<void> _unlockAndPick(BuildContext context) async {
    final premium = await getIt<RevenueCatService>().presentPaywall();
    if (premium && context.mounted) Navigator.pop(context, plan);
  }

  @override
  Widget build(BuildContext context) {
    // Premium kullanıcıda kilit görünmez.
    return ValueListenableBuilder<bool>(
      valueListenable: getIt<RevenueCatService>().isPremium,
      builder: (context, isPremium, _) =>
          _buildCard(context, locked: plan.isLocked && !isPremium),
    );
  }

  Widget _buildCard(BuildContext context, {required bool locked}) {
    return GestureDetector(
      onTap: locked
          ? () => unawaited(_unlockAndPick(context))
          : () => Navigator.pop(context, plan),
      child: Container(
        width: _kCardWidth,
        height: _kCardHeight,
        decoration: BoxDecoration(
          color: ColorName.colorWhite,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: ColorName.colorOptionSelected, width: 2)
              : null,
          boxShadow: _shadows,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(selected ? 14 : 16),
          child: locked ? _LockedBody(plan: plan) : _CardBody(plan: plan),
        ),
      ),
    );
  }
}

final class _CardBody extends StatelessWidget {
  const _CardBody({required this.plan});

  final PlansCardData plan;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 16,
          top: 16,
          bottom: -16,
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topRight,
              child: Text(
                plan.watermark,
                style: AppTextStyles.plansCardWatermark.copyWith(
                  color: plan.accentColor.withValues(alpha: 0.22),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(plan.title, style: AppTextStyles.planOptionTitle),
                  const SizedBox(width: 8),
                  _IntensityBolts(filled: plan.intensity),
                ],
              ),
              Text(
                plan.subtitleKey.tr(),
                style: AppTextStyles.optionSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: plan.chipBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    plan.chipKey.tr(),
                    style: AppTextStyles.plansChipLabel.copyWith(
                      color: plan.chipFg,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _LockedBody extends StatelessWidget {
  const _LockedBody({required this.plan});

  final PlansCardData plan;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: _CardBody(plan: plan),
        ),
        ColoredBox(
          color: ColorName.colorPlanLockedOverlay.withValues(alpha: 0.09),
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              border: Border.fromBorderSide(
                BorderSide(color: ColorName.colorWhite, width: 2),
              ),
            ),
          ),
        ),
        const Center(child: _PremiumLockBadge()),
      ],
    );
  }
}

final class _IntensityBolts extends StatelessWidget {
  const _IntensityBolts({required this.filled});

  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_kMaxIntensity, (index) {
        final isOn = index < filled;
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 3),
          child: Opacity(
            opacity: isOn ? 1 : 0.18,
            child: AppImages.lightning.image(
              width: _kBoltSize,
              height: _kBoltSize,
              fit: BoxFit.contain,
            ),
          ),
        );
      }),
    );
  }
}

final class _PremiumLockBadge extends StatelessWidget {
  const _PremiumLockBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.10),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.09),
            offset: const Offset(0, 6),
            blurRadius: 10,
          ),
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.05),
            offset: const Offset(0, 12),
            blurRadius: 16,
          ),
        ],
      ),
      child: AppImages.kingSl.image(fit: BoxFit.contain),
    );
  }
}
