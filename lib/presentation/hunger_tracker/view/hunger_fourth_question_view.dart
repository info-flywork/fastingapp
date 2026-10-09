import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/domain/hunger/hunger_repository.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_session_args.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_result_type.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_symptom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/hunger_fourth_question_view_mixin.dart';

enum HungerFourthAnswer { almostAnything, somethingSweet, fastFood, notSure }

/// Hızlı kontrol — dördüncü soru (ne istiyorsun?).
final class HungerFourthQuestionView extends StatefulWidget {
  const HungerFourthQuestionView({
    super.key,
    this.args = const HungerFlowArgs(),
  });

  final HungerFlowArgs args;

  @override
  State<HungerFourthQuestionView> createState() =>
      _HungerFourthQuestionViewState();
}

class _HungerFourthQuestionViewState extends State<HungerFourthQuestionView>
    with HungerFourthQuestionViewMixin {
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
                                  'hunger_fourth_question_page.title_line1'
                                      .tr(),
                                  style: AppTextStyles.hungerCheckTitle,
                                ),
                                Text(
                                  'hunger_fourth_question_page.title_line2'
                                      .tr(),
                                  style: AppTextStyles.hungerCheckTitle,
                                ),
                                Text(
                                  'hunger_fourth_question_page.title_line3'
                                      .tr(),
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
                        child: AppImages.fourthQuestion.image(
                          width: 245,
                          height: 245,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 188),
                      child: Column(
                        children: [
                          _AnswerCard(
                            icon: AppImages.almostAny,
                            labelKey:
                                'hunger_fourth_question_page.opt_almost_any',
                            selected:
                                selected == HungerFourthAnswer.almostAnything,
                            onTap: () =>
                                selectAnswer(HungerFourthAnswer.almostAnything),
                          ),
                          const SizedBox(height: 12),
                          _AnswerCard(
                            icon: AppImages.donut,
                            labelKey: 'hunger_fourth_question_page.opt_sweet',
                            selected:
                                selected == HungerFourthAnswer.somethingSweet,
                            onTap: () =>
                                selectAnswer(HungerFourthAnswer.somethingSweet),
                          ),
                          const SizedBox(height: 12),
                          _AnswerCard(
                            icon: AppImages.friedPotato,
                            labelKey:
                                'hunger_fourth_question_page.opt_fast_food',
                            selected: selected == HungerFourthAnswer.fastFood,
                            onTap: () =>
                                selectAnswer(HungerFourthAnswer.fastFood),
                          ),
                          const SizedBox(height: 12),
                          _AnswerCard(
                            icon: AppImages.mood,
                            labelKey:
                                'hunger_fourth_question_page.opt_not_sure',
                            selected: selected == HungerFourthAnswer.notSure,
                            onTap: () =>
                                selectAnswer(HungerFourthAnswer.notSure),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _ResultBar(
              bottomInset: bottom,
              onPressed: onResultTapped,
              isEnabled: selected != null,
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

final class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.icon,
    required this.labelKey,
    required this.selected,
    required this.onTap,
  });

  final AppImageAsset icon;
  final String labelKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: double.infinity,
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
            icon.image(width: 32, height: 32, fit: BoxFit.contain),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                labelKey.tr(),
                style: AppTextStyles.hungerCheckCardTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ResultBar extends StatelessWidget {
  const _ResultBar({
    required this.bottomInset,
    required this.onPressed,
    required this.isEnabled,
  });

  final double bottomInset;
  final VoidCallback onPressed;
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
          label: 'hunger_fourth_question_page.result'.tr(),
          onPressed: onPressed,
          isEnabled: isEnabled,
          decoration: AppButtonDecoration.primary(),
          showIcon: false,
        ),
      ),
    );
  }
}
