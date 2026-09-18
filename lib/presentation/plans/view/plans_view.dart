import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/plans/plan_detail_args.dart';
import 'package:fastingapp/presentation/plans/plans_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

const _kHeaderHeight = 56.0;
const _kCardWidth = 271.0;
const _kCardHeight = 144.0;
const _kCardGap = 16.0;
const _kMaxIntensity = 4;
const _kBoltSize = 18.0;

/// Planlar sekmesi — seviye başına 2 satır, yatay kaydırmalı kartlar.
final class PlansView extends StatefulWidget {
  const PlansView({super.key});

  @override
  State<PlansView> createState() => _PlansViewState();
}

class _PlansViewState extends State<PlansView> {
  PlansCardData? _selected;

  Future<void> _openPlanDetail({
    required PlansCardData data,
    required String detailTitleKey,
  }) async {
    if (data.isLocked) return;
    final result = await context.pushNamed<PlansCardData>(
      RoutePaths.planDetail.name,
      extra: PlanDetailArgs(plan: data, pageTitleKey: detailTitleKey),
    );
    if (!mounted || result == null) return;
    setState(() => _selected = result);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: ColorName.colorWhite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ColoredBox(
              color: ColorName.colorWhite,
              child: SizedBox(
                height: _kHeaderHeight,
                width: double.infinity,
                child: _PlansHeader(),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: ColorName.colorWhite,
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(top: 8, bottom: bottom + 100),
                  children: [
                    _PlansSection(
                      titleKey: 'plans.beginner_title',
                      emphasisKey: 'plans.beginner_emphasis',
                      restKey: 'plans.beginner_rest',
                      detailTitleKey: 'plans.detail_beginner_title',
                      row1: PlansCatalog.beginnerRow1,
                      row2: PlansCatalog.beginnerRow2,
                      selected: _selected,
                      onOpenPlan: _openPlanDetail,
                    ),
                    const SizedBox(height: 32),
                    _PlansSection(
                      titleKey: 'plans.advanced_title',
                      emphasisKey: 'plans.advanced_emphasis',
                      restKey: 'plans.advanced_rest',
                      detailTitleKey: 'plans.detail_advanced_title',
                      row1: PlansCatalog.advancedRow1,
                      row2: PlansCatalog.advancedRow2,
                      selected: _selected,
                      onOpenPlan: _openPlanDetail,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PlansHeader extends StatelessWidget {
  const _PlansHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Text(
          'plans.title'.tr(),
          style: AppTextStyles.plansPageTitle,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

final class _PlansSection extends StatelessWidget {
  const _PlansSection({
    required this.titleKey,
    required this.emphasisKey,
    required this.restKey,
    required this.detailTitleKey,
    required this.row1,
    required this.row2,
    required this.selected,
    required this.onOpenPlan,
  });

  final String titleKey;
  final String emphasisKey;
  final String restKey;
  final String detailTitleKey;
  final List<PlansCardData> row1;
  final List<PlansCardData> row2;
  final PlansCardData? selected;
  final Future<void> Function({
    required PlansCardData data,
    required String detailTitleKey,
  }) onOpenPlan;

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
        _PlansHorizontalRow(
          cards: row1,
          detailTitleKey: detailTitleKey,
          selected: selected,
          onOpenPlan: onOpenPlan,
        ),
        const SizedBox(height: _kCardGap),
        _PlansHorizontalRow(
          cards: row2,
          detailTitleKey: detailTitleKey,
          selected: selected,
          onOpenPlan: onOpenPlan,
        ),
      ],
    );
  }
}

final class _PlansHorizontalRow extends StatelessWidget {
  const _PlansHorizontalRow({
    required this.cards,
    required this.detailTitleKey,
    required this.selected,
    required this.onOpenPlan,
  });

  final List<PlansCardData> cards;
  final String detailTitleKey;
  final PlansCardData? selected;
  final Future<void> Function({
    required PlansCardData data,
    required String detailTitleKey,
  }) onOpenPlan;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kCardHeight + 12,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: _kCardGap),
        itemBuilder: (context, index) {
          final data = cards[index];
          return _PlanCard(
            data: data,
            detailTitleKey: detailTitleKey,
            isSelected: selected == data,
            onOpenPlan: onOpenPlan,
          );
        },
      ),
    );
  }
}

final class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.data,
    required this.detailTitleKey,
    required this.isSelected,
    required this.onOpenPlan,
  });

  final PlansCardData data;
  final String detailTitleKey;
  final bool isSelected;
  final Future<void> Function({
    required PlansCardData data,
    required String detailTitleKey,
  }) onOpenPlan;

  static const _cardWidth = _kCardWidth - 20;

  static const _cardShadows = <BoxShadow>[
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(color: Color(0x17000000), offset: Offset(0, 6), blurRadius: 10),
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 12), blurRadius: 16),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onOpenPlan(data: data, detailTitleKey: detailTitleKey),
      child: Container(
        width: _cardWidth,
        height: _kCardHeight,
        decoration: BoxDecoration(
          color: ColorName.colorWhite,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: ColorName.colorOptionSelected, width: 2)
              : null,
          boxShadow: _cardShadows,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSelected ? 14 : 16),
          child: data.isLocked ? _buildLockedBody() : _buildCardBody(),
        ),
      ),
    );
  }

  Widget _buildCardBody() {
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
                data.watermark,
                style: AppTextStyles.plansCardWatermark.copyWith(
                  color: data.accentColor.withValues(alpha: 0.22),
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
                  Text(data.title, style: AppTextStyles.planOptionTitle),
                  const SizedBox(width: 8),
                  _IntensityBolts(filled: data.intensity),
                ],
              ),
              Text(
                data.subtitleKey.tr(),
                style: AppTextStyles.optionSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: data.chipBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    data.chipKey.tr(),
                    style: AppTextStyles.plansChipLabel.copyWith(
                      color: data.chipFg,
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

  Widget _buildLockedBody() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: _buildCardBody(),
        ),
        ColoredBox(
          color: ColorName.colorPlanLockedOverlay.withValues(alpha: 0.09),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ColorName.colorWhite, width: 2),
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
          child: isOn
              ? Assets.images.lightning.image(
                  width: _kBoltSize,
                  height: _kBoltSize,
                  fit: BoxFit.contain,
                )
              : Opacity(
                  opacity: 0.18,
                  child: Assets.images.lightning.image(
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
      decoration: const BoxDecoration(
        color: ColorName.colorWhite,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
          BoxShadow(
            color: Color(0x17000000),
            offset: Offset(0, 6),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 12),
            blurRadius: 16,
          ),
        ],
      ),
      child: Assets.images.kingSl.image(fit: BoxFit.contain),
    );
  }
}
