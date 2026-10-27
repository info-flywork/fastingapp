import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Aktif oruç varken plan değiştirme seçimi.
enum PlanChangeWhileFastingAction {
  /// Mevcut orucu iptal et, yeni planı kaydet (yeni oruç başlatma).
  cancelExistingFast,

  /// Yeni plana başlamayı reddet — hiçbir şey yapma.
  reject,

  /// Mevcut orucu iptal et, yeni planı kaydet, aynı başlangıçla yeni oruç aç.
  restartWithSameData,

  /// Yeni planı kaydet; süren oruç kendi hedefiyle aynen devam etsin, plan
  /// bir sonraki oruçtan geçerli olsun.
  applyFromNextFast,
}

/// Aktif oruç varken "Bu plana başla" onayı.
final class PlanChangeWhileFastingDialog extends StatelessWidget {
  const PlanChangeWhileFastingDialog({super.key});

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
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'plans.active_fast_title'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.fastingEndTitle,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'plans.active_fast_body'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.fastingEndBody,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'plans.active_fast_cancel_existing'.tr(),
                            onPressed: () => Navigator.of(context).pop(
                              PlanChangeWhileFastingAction.cancelExistingFast,
                            ),
                            showIcon: false,
                            fontSize: 14,
                            decoration: AppButtonDecoration.endFastCancel(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'plans.active_fast_reject'.tr(),
                            onPressed: () => Navigator.of(
                              context,
                            ).pop(PlanChangeWhileFastingAction.reject),
                            showIcon: false,
                            fontSize: 14,
                            decoration: AppButtonDecoration.homeJoin(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'plans.active_fast_restart_same'.tr(),
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(PlanChangeWhileFastingAction.restartWithSameData),
                      showIcon: false,
                      decoration: AppButtonDecoration.fastingStartConfirm(),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'plans.active_fast_next'.tr(),
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(PlanChangeWhileFastingAction.applyFromNextFast),
                      showIcon: false,
                      decoration: AppButtonDecoration.fastingAnother(),
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
      width: PlanChangeWhileFastingDialog._badgeSize,
      height: PlanChangeWhileFastingDialog._badgeSize,
      decoration: BoxDecoration(
        color: ColorName.colorProfileBack,
        shape: BoxShape.circle,
        border: Border.all(color: ColorName.colorWhite, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: Transform.scale(
        scale: 1.1,
        child: AppImages.endFast.image(
          width: PlanChangeWhileFastingDialog._badgeSize,
          height: PlanChangeWhileFastingDialog._badgeSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
