import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/utils/extensions/future_extensions.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/flip_clock_unit.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// İlk oruç kaydı sonrası kutlama ekranı.
@immutable
final class FastingFirstTimeArgs {
  const FastingFirstTimeArgs({required this.elapsed});

  final Duration elapsed;
}

/// Orucu kaydet sonrası ilk kez tamamlama kutlaması.
final class FastingFirstTimeView extends StatelessWidget {
  const FastingFirstTimeView({required this.args, super.key});

  final FastingFirstTimeArgs args;

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    final hours = args.elapsed.inHours;
    final minutes = args.elapsed.inMinutes.remainder(60);
    final seconds = args.elapsed.inSeconds.remainder(60);
    final time =
        '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
    await SharePlus.instance.share(
      ShareParams(
        text: '${'fasting_page.first_time_title'.tr()}\n$time',
        sharePositionOrigin: origin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final hours = args.elapsed.inHours;
    final minutes = args.elapsed.inMinutes.remainder(60);
    final seconds = args.elapsed.inSeconds.remainder(60);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorWhite,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: top + 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: _CloseButton(onTap: () => context.pop(true)),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  children: [
                    Text(
                      'fasting_page.finish_total'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.fastingFirstTimeTotal,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FlipClockUnit(
                          value: hours,
                          label: 'home.timer_hrs'.tr(),
                        ),
                        const SizedBox(width: 8),
                        FlipClockUnit(
                          value: minutes,
                          label: 'home.timer_min'.tr(),
                        ),
                        const SizedBox(width: 8),
                        FlipClockUnit(
                          value: seconds,
                          label: 'home.timer_sec'.tr(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AppImages.firstTime.image(
                      width: 280,
                      height: 280,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'fasting_page.first_time_title'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.fastingFirstTimeTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'fasting_page.first_time_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.fastingFirstTimeSubtitle,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, math.max(bottom, 24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    label: 'fasting_page.first_time_share'.tr(),
                    onPressed: () => _share(context).withLoading(context),
                    decoration: AppButtonDecoration.hungerResult(),
                    iconPosition: AppButtonIconPosition.leading,
                    icon: Assets.icons.solarSquareShareLineLineDuotone.svg(
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        ColorName.colorWhite,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.pop(true),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'fasting_page.first_time_continue'.tr(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.fastingFinishContinue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma Frame 1597878668 — 44×44, radius 999, #F6F6F6, −180°.
final class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorFlipClock,
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
              child: const Icon(
                Icons.close_rounded,
                size: 20,
                color: ColorName.colorTitle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
