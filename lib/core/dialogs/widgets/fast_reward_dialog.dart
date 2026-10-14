import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/domain/fasting/fasting_repository.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Oruç bitince kazanımlar: seri, XP, seviye, Mochi adası, meydan okuma
/// (sunucu `POST /fasts/:id/finish` yanıtı).
final class FastRewardDialog extends StatelessWidget {
  const FastRewardDialog({required this.result, super.key});

  final FinishFastResult result;

  @override
  Widget build(BuildContext context) {
    final rows = <(AppImageAsset, String)>[
      if (result.streakIncreased)
        (
          AppImages.streakFlame,
          'fasting_finish.reward_streak'.tr(args: ['${result.streak}']),
        ),
      if (result.xpGained > 0)
        (
          AppImages.kingSl,
          'fasting_finish.reward_xp'.tr(args: ['${result.xpGained}']),
        ),
      if (result.levelUpTo case final level?)
        (AppImages.kingSl, 'fasting_finish.reward_level'.tr(args: ['$level'])),
      if (result.worldLevelUps > 0)
        (AppImages.mochiWorld1, 'fasting_finish.reward_world'.tr()),
      if (result.challengesCompleted > 0)
        (AppImages.challenge, 'fasting_finish.reward_challenge'.tr()),
    ];
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                'fasting_finish.reward_title'.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.fastingEndTitle,
              ),
              const SizedBox(height: 16),
              for (final (icon, text) in rows) ...[
                Row(
                  children: [
                    icon.image(width: 36, height: 36, fit: BoxFit.contain),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(text, style: AppTextStyles.fastingEndBody),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              AppButton(
                label: 'fasting_finish.reward_continue'.tr(),
                showIcon: false,
                decoration: AppButtonDecoration.homeJoin(),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
