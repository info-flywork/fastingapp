import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_symptom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/hunger_third_question_view_mixin.dart';

/// Hızlı kontrol — üçüncü soru (beden belirtileri).
final class HungerThirdQuestionView extends StatefulWidget {
  const HungerThirdQuestionView({
    super.key,
    this.args = const HungerFlowArgs(),
  });

  final HungerFlowArgs args;

  @override
  State<HungerThirdQuestionView> createState() =>
      _HungerThirdQuestionViewState();
}

class _HungerThirdQuestionViewState extends State<HungerThirdQuestionView>
    with HungerThirdQuestionViewMixin {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      height: 180,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'hunger_third_question_page.title_line1'.tr(),
                                  style: AppTextStyles.hungerCheckTitle,
                                ),
                                Text(
                                  'hunger_third_question_page.title_line2'.tr(),
                                  style: AppTextStyles.hungerCheckTitle,
                                ),
                                Text(
                                  'hunger_third_question_page.title_line3'.tr(),
                                  style: AppTextStyles.hungerCheckTitle,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 140),
                        ],
                      ),
                    ),
                    Positioned(
                      right: -28,
                      top: -8,
                      child: IgnorePointer(
                        child: Assets.images.thirdSQuestion.image(
                          width: 245,
                          height: 245,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 180),
                      child: _BodyNoticeGrid(
                        selected: selected,
                        onToggle: toggleNotice,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _NextBar(
              bottomInset: bottom,
              onNext: onNextTapped,
              isEnabled: selected.isNotEmpty,
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

final class _BodyNoticeGrid extends StatelessWidget {
  const _BodyNoticeGrid({required this.selected, required this.onToggle});

  final Set<HungerBodyNotice> selected;
  final ValueChanged<HungerBodyNotice> onToggle;

  static final _items = <(HungerBodyNotice, String, AssetGenImage)>[
    (
      HungerBodyNotice.stomachGrowling,
      'hunger_third_question_page.opt_stomach',
      Assets.images.stomach,
    ),
    (
      HungerBodyNotice.lowEnergy,
      'hunger_third_question_page.opt_low_energy',
      Assets.images.yellowLightning,
    ),
    (
      HungerBodyNotice.dizziness,
      'hunger_third_question_page.opt_dizziness',
      Assets.images.dizzinies,
    ),
    (
      HungerBodyNotice.nausea,
      'hunger_third_question_page.opt_nausea',
      Assets.images.nausea,
    ),
    (
      HungerBodyNotice.fatigue,
      'hunger_third_question_page.opt_fatigue',
      Assets.images.fatigue,
    ),
    (
      HungerBodyNotice.nothingPhysical,
      'hunger_third_question_page.opt_nothing',
      Assets.images.nothingPhysical,
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
                child: _BodyNoticeChip(
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

final class _BodyNoticeChip extends StatelessWidget {
  const _BodyNoticeChip({
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
        height: 60,
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
            icon.image(width: 24, height: 24, fit: BoxFit.contain),
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
