import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_symptom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/hunger_first_question_view_mixin.dart';

enum HungerFirstAnswer { yes, notReally, notSure }

/// Hızlı kontrol — ilk soru.
final class HungerFirstQuestionView extends StatefulWidget {
  const HungerFirstQuestionView({
    super.key,
    this.args = const HungerFlowArgs(),
  });

  final HungerFlowArgs args;

  @override
  State<HungerFirstQuestionView> createState() =>
      _HungerFirstQuestionViewState();
}

class _HungerFirstQuestionViewState extends State<HungerFirstQuestionView>
    with HungerFirstQuestionViewMixin {
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'hunger_first_question_page.title'.tr(),
                                style: AppTextStyles.hungerCheckTitle,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'hunger_first_question_page.question'.tr(),
                                style: AppTextStyles.hungerCheckSubtitle,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 140),
                      ],
                    ),
                    Positioned(
                      right: -28,
                      top: -8,
                      child: IgnorePointer(
                        child: AppImages.firstQuestion.image(
                          width: 245,
                          height: 245,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // İlk kart mascotun üstünde → alt kısmı örtülür
                    Padding(
                      padding: const EdgeInsets.only(top: 180),
                      child: Column(
                        children: [
                          _AnswerCard(
                            labelKey: 'hunger_first_question_page.opt_yes',
                            selected: selected == HungerFirstAnswer.yes,
                            onTap: () => selectAnswer(HungerFirstAnswer.yes),
                          ),
                          const SizedBox(height: 12),
                          _AnswerCard(
                            labelKey:
                                'hunger_first_question_page.opt_not_really',
                            selected: selected == HungerFirstAnswer.notReally,
                            onTap: () =>
                                selectAnswer(HungerFirstAnswer.notReally),
                          ),
                          const SizedBox(height: 12),
                          _AnswerCard(
                            labelKey: 'hunger_first_question_page.opt_not_sure',
                            selected: selected == HungerFirstAnswer.notSure,
                            onTap: () =>
                                selectAnswer(HungerFirstAnswer.notSure),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _NextBar(
              bottomInset: bottom,
              onNext: onNextTapped,
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
    required this.labelKey,
    required this.selected,
    required this.onTap,
  });

  final String labelKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ColorName.colorWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (selected)
              AppImages.greenTickFilled.image(
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
              ),
            const SizedBox(width: 10),
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
