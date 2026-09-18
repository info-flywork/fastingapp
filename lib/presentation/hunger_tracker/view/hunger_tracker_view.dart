import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_symptom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/hunger_tracker_view_mixin.dart';

/// Açlık takibi — semptom seçimi + CTA.
final class HungerTrackerView extends StatefulWidget {
  const HungerTrackerView({super.key});

  @override
  State<HungerTrackerView> createState() => _HungerTrackerViewState();
}

class _HungerTrackerViewState extends State<HungerTrackerView>
    with HungerTrackerViewMixin {
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorBodyPageBg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: top + 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _CircleBackButton(onTap: () => context.pop()),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'hunger_tracker_page.title_line1'.tr(),
                                  style: AppTextStyles.hungerTrackerTitle,
                                ),
                                Text(
                                  'hunger_tracker_page.title_line2'.tr(),
                                  style: AppTextStyles.hungerTrackerTitle,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'hunger_tracker_page.subtitle'.tr(),
                                  style: AppTextStyles.hungerTrackerSubtitle,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IgnorePointer(
                            child: Assets.images.listenYourBody.image(
                              width: 148,
                              height: 148,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Şimdi açım / geçmiş
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: ColorName.colorWhite,
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _ActionCard(
                                  background: ColorName.colorMealCream,
                                  icon: Assets.images.stomach,
                                  iconSize: 70,
                                  titleKey: 'hunger_tracker_page.hungry_now',
                                  subtitleKey:
                                      'hunger_tracker_page.hungry_now_sub',
                                  onTap: onHungryNowTapped,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionCard(
                                  background: ColorName.colorHungerHistoryBg,
                                  icon: Assets.images.analytics,
                                  titleKey: 'hunger_tracker_page.history',
                                  subtitleKey:
                                      'hunger_tracker_page.history_sub',
                                  onTap: onHistoryTapped,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Yaygın belirtiler
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: ColorName.colorWhite,
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'hunger_tracker_page.symptoms_title'.tr(),
                                      style: AppTextStyles.hungerSymptomsTitle,
                                    ),
                                  ),
                                  Text(
                                    'hunger_tracker_page.symptoms_hint'.tr(),
                                    style: AppTextStyles.hungerSymptomsHint,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _SymptomsGrid(
                                selected: selectedSymptoms,
                                onToggle: toggleSymptom,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _NextBar(
              bottomInset: bottom,
              onNext: onNextTapped,
              isEnabled: selectedSymptoms.isNotEmpty,
            ),
          ],
        ),
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

final class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.background,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.onTap,
    this.iconSize = 56,
  });

  final Color background;
  final AssetGenImage icon;
  final double iconSize;
  final String titleKey;
  final String subtitleKey;
  final VoidCallback onTap;

  static const double _height = 174;
  static const double _iconSlot = 70;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _height,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            SizedBox(
              height: _iconSlot,
              child: Center(
                child: icon.image(
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              titleKey.tr(),
              style: AppTextStyles.hungerActionTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                subtitleKey.tr(),
                style: AppTextStyles.hungerActionSubtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SymptomsGrid extends StatelessWidget {
  const _SymptomsGrid({required this.selected, required this.onToggle});

  final Set<HungerSymptom> selected;
  final ValueChanged<HungerSymptom> onToggle;

  static final _items = <(HungerSymptom, String, AssetGenImage)>[
    (
      HungerSymptom.sleeplessness,
      'hunger_tracker_page.symptom_sleeplessness',
      Assets.images.zzz,
    ),
    (
      HungerSymptom.headache,
      'hunger_tracker_page.symptom_headache',
      Assets.images.yellowLightning,
    ),
    (
      HungerSymptom.dizziness,
      'hunger_tracker_page.symptom_dizziness',
      Assets.images.dizzinies,
    ),
    (
      HungerSymptom.nausea,
      'hunger_tracker_page.symptom_nausea',
      Assets.images.nausea,
    ),
    (
      HungerSymptom.fatigue,
      'hunger_tracker_page.symptom_fatigue',
      Assets.images.fatigue,
    ),
    (
      HungerSymptom.weakness,
      'hunger_tracker_page.symptom_weakness',
      Assets.images.weakness,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chipW = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in _items)
              SizedBox(
                width: chipW,
                child: _SymptomChip(
                  labelKey: item.$2,
                  icon: item.$3,
                  selected: selected.contains(item.$1),
                  onTap: () => onToggle(item.$1),
                ),
              ),
          ],
        );
      },
    );
  }
}

final class _SymptomChip extends StatelessWidget {
  const _SymptomChip({
    required this.labelKey,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String labelKey;
  final AssetGenImage icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ColorName.colorWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? ColorName.colorOptionSelected
                : ColorName.colorBlack.withValues(alpha: 0.05),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            icon.image(width: 26, height: 24, fit: BoxFit.contain),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                labelKey.tr(),
                style: AppTextStyles.hungerSymptomLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _NextBar extends StatelessWidget {
  const _NextBar({
    required this.bottomInset,
    required this.onNext,
    required this.isEnabled,
  });

  final double bottomInset;
  final VoidCallback onNext;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    // Figma Frame 48096339: top radius 32, pad 16/16/24/16, #FFF
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
        child: AppButton(
          label: 'hunger_tracker_page.next'.tr(),
          onPressed: onNext,
          isEnabled: isEnabled,
          decoration: AppButtonDecoration.primary(),
          showIcon: false,
        ),
      ),
    );
  }
}
