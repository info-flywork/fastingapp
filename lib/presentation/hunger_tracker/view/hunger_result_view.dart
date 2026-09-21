import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_result_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/hunger_result_view_mixin.dart';

/// Hızlı kontrol sonucu — physical / emotional.
final class HungerResultView extends StatefulWidget {
  const HungerResultView({required this.type, super.key});

  final HungerResultType type;

  @override
  State<HungerResultView> createState() => _HungerResultViewState();
}

class _HungerResultViewState extends State<HungerResultView>
    with HungerResultViewMixin {
  bool get _isPhysical => widget.type == HungerResultType.physical;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final bg = _isPhysical
        ? ColorName.colorBodyPageBg
        : ColorName.colorEmotionalHungerBg;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
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
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: Column(
                  children: [
                    (_isPhysical
                            ? Assets.images.physicalHunger
                            : Assets.images.emotionalHunger)
                        .image(width: 220, height: 235, fit: BoxFit.contain),

                    _Badge(
                      labelKey: _isPhysical
                          ? 'hunger_result_page.physical_badge'
                          : 'hunger_result_page.emotional_badge',
                      background: _isPhysical
                          ? ColorName.colorMealPositive.withValues(alpha: 0.2)
                          : ColorName.colorEmotionalHungerBadge.withValues(
                              alpha: 0.2,
                            ),
                      textColor: _isPhysical
                          ? ColorName.colorPhysicalHungerBadgeText
                          : ColorName.colorEmotionalHungerBadgeText,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (_isPhysical
                              ? 'hunger_result_page.physical_title'
                              : 'hunger_result_page.emotional_title')
                          .tr(),
                      style: AppTextStyles.hungerResultTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (_isPhysical
                              ? 'hunger_result_page.physical_body'
                              : 'hunger_result_page.emotional_body')
                          .tr(),
                      style: AppTextStyles.hungerResultBody,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _RecommendationsCard(
                      isPhysical: _isPhysical,
                      titleKey: _isPhysical
                          ? 'hunger_result_page.physical_rec_title'
                          : 'hunger_result_page.emotional_rec_title',
                      titleColor: _isPhysical
                          ? ColorName.colorPhysicalHungerRecTitle
                          : ColorName.colorEmotionalHungerRecTitle,
                      itemKeys: _isPhysical
                          ? const [
                              'hunger_result_page.physical_rec_1',
                              'hunger_result_page.physical_rec_2',
                              'hunger_result_page.physical_rec_3',
                            ]
                          : const [
                              'hunger_result_page.emotional_rec_1',
                              'hunger_result_page.emotional_rec_2',
                              'hunger_result_page.emotional_rec_3',
                              'hunger_result_page.emotional_rec_4',
                            ],
                    ),
                  ],
                ),
              ),
            ),
            if (_isPhysical)
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: ColorName.colorWhite,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    math.max(bottom, 24),
                  ),
                  child: _ResultActions(
                    onPrimary: onPrimaryTapped,
                    onSecondary: onSecondaryTapped,
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, bottom),
                child: _ResultActions(
                  onPrimary: onPrimaryTapped,
                  onSecondary: onSecondaryTapped,
                ),
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

final class _ResultActions extends StatelessWidget {
  const _ResultActions({required this.onPrimary, required this.onSecondary});

  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: 'hunger_result_page.primary'.tr(),
          onPressed: onPrimary,
          decoration: AppButtonDecoration.hungerResult(),
          showIcon: false,
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onSecondary,
          behavior: HitTestBehavior.opaque,
          child: Text(
            'hunger_result_page.secondary'.tr(),
            style: AppTextStyles.hungerResultSecondary,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

final class _Badge extends StatelessWidget {
  const _Badge({
    required this.labelKey,
    required this.background,
    required this.textColor,
  });

  final String labelKey;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        labelKey.tr(),
        style: AppTextStyles.hungerResultBadge.copyWith(color: textColor),
        textAlign: TextAlign.center,
      ),
    );
  }
}

final class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({
    required this.isPhysical,
    required this.titleKey,
    required this.titleColor,
    required this.itemKeys,
  });

  final bool isPhysical;
  final String titleKey;
  final Color titleColor;
  final List<String> itemKeys;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _RecRow(
        labelKey: titleKey,
        style: AppTextStyles.hungerResultRecTitle.copyWith(color: titleColor),
      ),
      for (final key in itemKeys)
        _RecRow(labelKey: key, style: AppTextStyles.hungerResultRecItem),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Container(
            width: double.infinity,

            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: isPhysical
                  ? ColorName.colorMealPositive.withValues(alpha: 0.1)
                  : ColorName.colorHungerResultCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  rows[i],
                ],
              ],
            ),
          ),
          if (isPhysical)
            Positioned(
              right: 0,
              top: 0,
              child: Assets.images.tree3.image(
                width: 119,
                height: 119,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }
}

final class _RecRow extends StatelessWidget {
  const _RecRow({required this.labelKey, required this.style});

  final String labelKey;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Assets.images.greenTickFilled.image(
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(labelKey.tr(), style: style)),
      ],
    );
  }
}
