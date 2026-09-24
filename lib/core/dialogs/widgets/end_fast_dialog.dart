import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Erken oruç bitirme onayı. `true` dönerse oruç biter.
final class EndFastDialog extends StatelessWidget {
  const EndFastDialog({super.key});

  static const _badgeSize = 72.0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: _badgeSize / 2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ColorName.colorWhite,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'fasting_struggle.end_fast_title'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.fastingEndTitle,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'fasting_struggle.end_fast_body'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.fastingEndBody,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'fasting_struggle.end_fast_yes'.tr(),
                            onPressed: () => Navigator.of(context).pop(true),
                            showIcon: false,
                            decoration: AppButtonDecoration.endFastCancel(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppButton(
                            label: 'fasting_struggle.end_fast_no'.tr(),
                            onPressed: () => Navigator.of(context).pop(false),
                            showIcon: false,
                            decoration: AppButtonDecoration.homeJoin(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const _FlagBadge(),
        ],
      ),
    );
  }
}

final class _FlagBadge extends StatelessWidget {
  const _FlagBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: EndFastDialog._badgeSize,
      height: EndFastDialog._badgeSize,
      decoration: BoxDecoration(
        color: ColorName.colorProfileBack,
        shape: BoxShape.circle,
        border: Border.all(color: ColorName.colorWhite, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: Transform.scale(
        scale: 1.1,
        child: Assets.images.endFast.image(
          width: EndFastDialog._badgeSize,
          height: EndFastDialog._badgeSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
