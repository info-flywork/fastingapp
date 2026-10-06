import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_symptom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/hunger_check_view_mixin.dart';

/// Açlık kontrolü seçimi — Quick / Full Check.
final class HungerCheckView extends StatefulWidget {
  const HungerCheckView({super.key, this.args = const HungerFlowArgs()});

  final HungerFlowArgs args;

  @override
  State<HungerCheckView> createState() => _HungerCheckViewState();
}

class _HungerCheckViewState extends State<HungerCheckView>
    with HungerCheckViewMixin {
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
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
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
                                    'hunger_check_page.title_line1'.tr(),
                                    style: AppTextStyles.hungerCheckTitle,
                                  ),
                                  Text(
                                    'hunger_check_page.title_line2'.tr(),
                                    style: AppTextStyles.hungerCheckTitle,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'hunger_check_page.subtitle'.tr(),
                                    style: AppTextStyles.hungerCheckSubtitle,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 168),
                          ],
                        ),
                        Positioned(
                          right: -28,
                          top: -12,
                          child: IgnorePointer(
                            child: AppImages.mascotSearch.image(
                              width: 250,
                              height: 250,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        // Kartlar mascotun üstünde → alt kısmı örtülür
                        Padding(
                          padding: const EdgeInsets.only(top: 175),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _CheckOptionCard(
                                icon: AppImages.yellowLightning,
                                titleKey: 'hunger_check_page.quick_title',
                                metaKey: 'hunger_check_page.quick_meta',
                                subtitleKey: 'hunger_check_page.quick_sub',
                                onTap: onQuickCheckTapped,
                              ),
                              const SizedBox(height: 12),
                              _CheckOptionCard(
                                icon: AppImages.fullCheck,
                                titleKey: 'hunger_check_page.full_title',
                                metaKey: 'hunger_check_page.full_meta',
                                subtitleKey: 'hunger_check_page.full_sub',
                                onTap: onFullCheckTapped,
                              ),
                              const SizedBox(height: 12),
                              const _TipBanner(),
                            ],
                          ),
                        ),
                      ],
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

final class _CheckOptionCard extends StatelessWidget {
  const _CheckOptionCard({
    required this.icon,
    required this.titleKey,
    required this.metaKey,
    required this.subtitleKey,
    required this.onTap,
  });

  final AppImageAsset icon;
  final String titleKey;
  final String metaKey;
  final String subtitleKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ColorName.colorWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            icon.image(width: 56, height: 56, fit: BoxFit.contain),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleKey.tr(),
                    style: AppTextStyles.hungerCheckCardTitle,
                  ),
                  const SizedBox(height: 6),
                  Text(metaKey.tr(), style: AppTextStyles.hungerCheckCardMeta),

                  const SizedBox(height: 6),
                  Text(
                    subtitleKey.tr(),
                    style: AppTextStyles.hungerCheckCardMeta,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AppImages.riiight.image(width: 10, height: 18),
          ],
        ),
      ),
    );
  }
}

final class _TipBanner extends StatelessWidget {
  const _TipBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorName.colorHungerTipBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          AppImages.tree.image(width: 48, height: 48, fit: BoxFit.contain),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              'hunger_check_page.tip'.tr(),
              style: AppTextStyles.hungerCheckTip,
            ),
          ),
        ],
      ),
    );
  }
}
