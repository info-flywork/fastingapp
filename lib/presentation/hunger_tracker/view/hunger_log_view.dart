import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/domain/hunger/hunger_store.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_result_type.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_session_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/hunger_log_view_mixin.dart';

/// Açlığı trackera kaydetme ekranı.
final class HungerLogView extends StatefulWidget {
  const HungerLogView({required this.type, this.session, super.key});

  final HungerResultType type;
  final HungerSessionArgs? session;

  @override
  State<HungerLogView> createState() => _HungerLogViewState();
}

class _HungerLogViewState extends State<HungerLogView> with HungerLogViewMixin {
  bool get _isPhysical => widget.type == HungerResultType.physical;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 160,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            height: 150,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'hunger_log_page.title_line1'.tr(),
                                        style: AppTextStyles.hungerCheckTitle,
                                      ),
                                      Text(
                                        'hunger_log_page.title_line2'.tr(),
                                        style: AppTextStyles.hungerCheckTitle,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'hunger_log_page.subtitle'.tr(),
                                        style: AppTextStyles.hungerLogSubtitle,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 120),
                              ],
                            ),
                          ),
                          Positioned(
                            right: -10,
                            top: 20,
                            child: IgnorePointer(
                              child: Transform.scale(
                                scale: 1.15,
                                child: AppImages.logHunger.image(
                                  width: 180,
                                  height: 180,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InfoCard(
                      icon: AppImages.leaf,
                      labelKey: 'hunger_log_page.hunger_type',
                      value:
                          (_isPhysical
                                  ? 'hunger_log_page.type_physical'
                                  : 'hunger_log_page.type_emotional')
                              .tr(),
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: AppImages.blueClock,
                      labelKey: 'hunger_log_page.time',
                      value: formattedTime,
                    ),
                    const SizedBox(height: 12),
                    _NotesCard(controller: notesController),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: ColorName.colorWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, math.max(bottom, 24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      label: 'hunger_log_page.save'.tr(),
                      onPressed: onSaveTapped,
                      decoration: AppButtonDecoration.hungerResult(),
                      showIcon: false,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: onSkipTapped,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        'hunger_log_page.skip'.tr(),
                        style: AppTextStyles.hungerResultSecondary,
                        textAlign: TextAlign.center,
                      ),
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

final class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.labelKey,
    required this.value,
  });

  final AppImageAsset icon;
  final String labelKey;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          icon.image(width: 48, height: 48, fit: BoxFit.contain),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(labelKey.tr(), style: AppTextStyles.hungerLogCardLabel),
                Text(value, style: AppTextStyles.hungerLogCardValue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppImages.blueBook.image(
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'hunger_log_page.notes'.tr(),
                  style: AppTextStyles.hungerLogCardLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 95,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ColorName.colorHungerNotesField,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: AppTextStyles.hungerLogNotesInput,
              cursorColor: ColorName.colorBrandStrong,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'hunger_log_page.notes_hint'.tr(),
                hintStyle: AppTextStyles.hungerLogNotesHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
