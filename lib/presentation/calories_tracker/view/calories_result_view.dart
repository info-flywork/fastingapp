import 'dart:io';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Çekilen yemeğin kalori sonucu.
final class CaloriesResultView extends StatelessWidget {
  const CaloriesResultView({required this.photoPath, super.key});

  final String photoPath;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ColorName.colorBlack,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (photoPath.isNotEmpty)
              Image.file(
                File(photoPath),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            Positioned(
              top: top + 8,
              left: 16,
              child: _CircleBackButton(onTap: () => context.pop()),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ResultSheet(bottomInset: math.max(bottom, 10)),
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
      elevation: 2,
      shadowColor: ColorName.colorBlack.withValues(alpha: 0.18),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Assets.icons.solarAltArrowUpLineDuotone.svg(
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                ColorName.colorTitle,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma Frame — üst radius 20, üstten şeffaf beyaza fade.
final class _ResultSheet extends StatelessWidget {
  const _ResultSheet({required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 120,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ColorName.colorWhite.withValues(alpha: 0),
                  ColorName.colorWhite.withValues(alpha: 0.05),
                  ColorName.colorWhite.withValues(alpha: 0.35),
                  ColorName.colorWhite.withValues(alpha: 0.8),
                  ColorName.colorWhite,
                ],
                stops: const [0, 0.28, 0.58, 0.82, 1],
              ),
            ),
          ),
        ),
        ColoredBox(
          color: ColorName.colorWhite,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'calories_result.meal_title'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caloriesResultTitle,
                ),
                const SizedBox(height: 10),
                Text(
                  'calories_result.kcal'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caloriesResultKcal,
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(
                      child: _MacroCard(
                        icon: _MacroIcon.protein,
                        labelKey: 'calories_result.protein',
                        valueKey: 'calories_result.protein_value',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _MacroCard(
                        icon: _MacroIcon.carbs,
                        labelKey: 'calories_result.carbs',
                        valueKey: 'calories_result.carbs_value',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _MacroCard(
                        icon: _MacroIcon.fats,
                        labelKey: 'calories_result.fats',
                        valueKey: 'calories_result.fats_value',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'calories_result.recalculate'.tr(),
                  onPressed: () => context.pop(),
                  decoration: AppButtonDecoration.hungerResult(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum _MacroIcon { protein, carbs, fats }

final class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.icon,
    required this.labelKey,
    required this.valueKey,
  });

  final _MacroIcon icon;
  final String labelKey;
  final String valueKey;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorName.colorBlack.withValues(alpha: 0.05),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _icon.image(width: 48, height: 48, fit: BoxFit.contain),
            const SizedBox(height: 10),
            Text(
              labelKey.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.caloriesResultMacroLabel,
            ),
            const SizedBox(height: 10),
            Text(
              valueKey.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.caloriesResultMacroValue,
            ),
          ],
        ),
      ),
    );
  }

  AppImageAsset get _icon => switch (icon) {
    _MacroIcon.protein => AppImages.protein,
    _MacroIcon.carbs => AppImages.carbs,
    _MacroIcon.fats => AppImages.olive,
  };
}
