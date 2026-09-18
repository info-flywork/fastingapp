import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/meal_records_view_mixin.dart';

const _kHeaderHeight = 56.0;

/// Öğün kayıtları detay — timeline + kayıt kartı + Save CTA.
final class MealRecordsView extends StatefulWidget {
  const MealRecordsView({super.key});

  @override
  State<MealRecordsView> createState() => _MealRecordsViewState();
}

class _MealRecordsViewState extends State<MealRecordsView>
    with MealRecordsViewMixin {
  @override
  void initState() {
    super.initState();
    initMealRecords();
  }

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
              SizedBox(
                height: _kHeaderHeight,
                width: double.infinity,
                child: _MealRecordsHeader(
                  dateLabel: dateLabel(context),
                  onDateTap: onDateSelectorTapped,
                ),
              ),
              Expanded(
                child: hasMealsForSelectedDate
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                        physics: const ClampingScrollPhysics(),
                        child: _MealTimeline(onMealTap: onMealCardTapped),
                      )
                    : const _MealRecordsEmptyState(),
              ),
              _SaveMealBar(bottomInset: bottom, onSave: onSaveMealTapped),
            ],
          ),
        ),
      ),
    );
  }
}

final class _MealRecordsHeader extends StatelessWidget {
  const _MealRecordsHeader({required this.dateLabel, required this.onDateTap});

  final String dateLabel;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _CircleIconButton(
            onTap: () => context.pop(),
            child: Transform.rotate(
              angle: math.pi,
              child: Assets.icons.solarAltArrowUpLineDuotoneRight.svg(
                width: 20,
                height: 20,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: onDateTap,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Assets.icons.solarCalendarMarkLineDuotone.svg(
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        ColorName.colorTitle,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(dateLabel, style: AppTextStyles.mealRecordsDateTitle),
                    const SizedBox(width: 4),
                    Transform.rotate(
                      angle: -math.pi / 2,
                      child: Assets.icons.solarAltArrowUpLineDuotone.svg(
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          ColorName.colorTitle,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
      ),
    );
  }
}

final class _MealRecordsEmptyState extends StatelessWidget {
  const _MealRecordsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Assets.images.confusing.image(
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          Text(
            'meal_records_page.empty_title'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.notificationsEmptyTitle,
          ),
          const SizedBox(height: 8),
          Text(
            'meal_records_page.empty_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.notificationsEmptySubtitle,
          ),
        ],
      ),
    );
  }
}

/// Home’daki timeline ile aynı yapı.
final class _MealTimeline extends StatelessWidget {
  const _MealTimeline({required this.onMealTap});

  final VoidCallback onMealTap;

  static const _lineColor = Color(0x993C3C43);
  static const _dotSize = 8.0;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                Container(
                  width: _dotSize * 1.5,
                  height: _dotSize * 1.5,
                  decoration: BoxDecoration(
                    color: _lineColor.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 1.5,
                      color: _lineColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _MealTimestamp(),
                const SizedBox(height: 10),
                _MealEntryCard(onTap: onMealTap),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _MealTimestamp extends StatelessWidget {
  const _MealTimestamp();

  @override
  Widget build(BuildContext context) {
    return Text(
      'home.meal_sample_time'.tr(),
      style: AppTextStyles.homeMealTimestamp,
    );
  }
}

/// Figma: 16r / pad 12 / border 2 #F6F6F6 / gap 16.
final class _MealEntryCard extends StatelessWidget {
  const _MealEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ColorName.colorWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ColorName.colorHomeChipBg, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: ColorName.colorStepsTrack,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Assets.images.orangeBell.image(
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _MealTag(labelKey: 'home.meal_tag_full'),
                  _MealTag(labelKey: 'home.meal_tag_keto'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Assets.images.mealRecordEmoji.image(
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _MealTag extends StatelessWidget {
  const _MealTag({required this.labelKey});

  final String labelKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: ColorName.colorHomeChipBg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(labelKey.tr(), style: AppTextStyles.homeMealTag),
    );
  }
}

/// Figma Frame 48096339 — üst 32r, pad 16/16/24/16, primary CTA.
final class _SaveMealBar extends StatelessWidget {
  const _SaveMealBar({required this.bottomInset, required this.onSave});

  final double bottomInset;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
      decoration: const BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: AppButton(
        label: 'meal_records_page.save_your_meal'.tr(),
        onPressed: onSave,
        decoration: AppButtonDecoration.primary(),
        showIcon: false,
      ),
    );
  }
}
