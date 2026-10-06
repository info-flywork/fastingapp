import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/hunger_success_view_mixin.dart';

/// Açlık kaydı sonrası başarı ekranı.
final class HungerSuccessView extends StatefulWidget {
  const HungerSuccessView({super.key});

  @override
  State<HungerSuccessView> createState() => _HungerSuccessViewState();
}

class _HungerSuccessViewState extends State<HungerSuccessView>
    with HungerSuccessViewMixin {
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    AppImages.greatJob.image(
                      width: 280,
                      height: 280,
                      fit: BoxFit.contain,
                    ),
                    Text(
                      'hunger_success_page.title'.tr(),
                      style: AppTextStyles.hungerResultTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'hunger_success_page.body'.tr(),
                      style: AppTextStyles.hungerResultBody,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 33),
                    _InsightsCard(onTap: onInsightsTapped),
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
                child: AppButton(
                  label: 'hunger_success_page.home'.tr(),
                  onPressed: onBackToHomeTapped,
                  decoration: AppButtonDecoration.hungerResult(),
                  showIcon: false,
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

final class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: ColorName.colorHungerInsightsCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AppImages.insightss.image(
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'hunger_success_page.insights'.tr(),
                style: AppTextStyles.hungerSuccessInsights,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
