import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/domain/nutrition/meals_repository.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/calories_result_view_mixin.dart';

/// Çekilen yemeğin kalori sonucu.
final class CaloriesResultView extends StatefulWidget {
  const CaloriesResultView({required this.photoPath, super.key});

  final String photoPath;

  @override
  State<CaloriesResultView> createState() => _CaloriesResultViewState();
}

class _CaloriesResultViewState extends State<CaloriesResultView>
    with CaloriesResultViewMixin {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final a = analysis;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ColorName.colorBlack,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.photoPath.isNotEmpty)
              Image.file(
                File(widget.photoPath),
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
              child: _ResultSheet(
                bottomInset: math.max(bottom, 10),
                loading: a == null && errorMessage == null,
                title: a?.mealTitle ?? 'calories_result.meal_title'.tr(),
                kcalText: a?.kcal != null ? '${a!.kcal} kcal' : '…',
                proteinG: a?.proteinG,
                carbsG: a?.carbsG,
                fatG: a?.fatG,
                errorMessage: errorMessage,
                canSave: a?.succeeded == true,
                saving: saving,
                onSave: onSaveMeal,
                onRetry: () => context.pop(),
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
  const _ResultSheet({
    required this.bottomInset,
    required this.loading,
    required this.title,
    required this.kcalText,
    required this.canSave,
    required this.saving,
    required this.onSave,
    required this.onRetry,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.errorMessage,
  });

  final double bottomInset;
  final bool loading;
  final String title;
  final String kcalText;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final String? errorMessage;
  final bool canSave;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onRetry;

  String _macro(double? g) => g != null ? '${g.round()}g' : '—';

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
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  )
                else ...[
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caloriesResultTitle,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    kcalText,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caloriesResultKcal,
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.hungerHistoryLogSubtitle,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MacroCard(
                          icon: _MacroIcon.protein,
                          labelKey: 'calories_result.protein',
                          valueText: _macro(proteinG),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MacroCard(
                          icon: _MacroIcon.carbs,
                          labelKey: 'calories_result.carbs',
                          valueText: _macro(carbsG),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MacroCard(
                          icon: _MacroIcon.fats,
                          labelKey: 'calories_result.fats',
                          valueText: _macro(fatG),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: canSave
                        ? 'hunger_log_page.save'.tr()
                        : 'calories_result.recalculate'.tr(),
                    onPressed: saving ? null : (canSave ? onSave : onRetry),
                    decoration: AppButtonDecoration.hungerResult(),
                  ),
                ],
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
    required this.valueText,
  });

  final _MacroIcon icon;
  final String labelKey;
  final String valueText;

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
              valueText,
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
