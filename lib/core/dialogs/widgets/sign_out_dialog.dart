import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Çıkış onayı. `true` dönerse oturum kapatılır.
final class SignOutDialog extends StatelessWidget {
  const SignOutDialog({super.key});

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
                      'profile.log_out_title'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.fastingEndTitle,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'profile.log_out_body'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.fastingEndBody,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'profile.log_out_confirm'.tr(),
                            onPressed: () => Navigator.of(context).pop(true),
                            showIcon: false,
                            decoration: AppButtonDecoration.endFastCancel(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppButton(
                            label: 'profile.log_out_cancel'.tr(),
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
          const _LogoutBadge(),
        ],
      ),
    );
  }
}

final class _LogoutBadge extends StatelessWidget {
  const _LogoutBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SignOutDialog._badgeSize,
      height: SignOutDialog._badgeSize,
      decoration: BoxDecoration(
        color: ColorName.colorProfileBack,
        shape: BoxShape.circle,
        border: Border.all(color: ColorName.colorWhite, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: Assets.icons.solarLogout2LineDuotone.svg(
        width: 28,
        height: 28,
        colorFilter: const ColorFilter.mode(
          ColorName.colorOptionNegative,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
