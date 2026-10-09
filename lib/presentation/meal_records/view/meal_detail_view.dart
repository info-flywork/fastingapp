import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/app_loading.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_option_card.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_option_card_style.dart';
import 'package:fastingapp/domain/nutrition/meals_repository.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:fastingapp/presentation/fasting/fasting_finish_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/meal_detail_view_mixin.dart';

enum MealKind { meal, snack }

enum MealDietChoice { ketogenic, lowCarb, mixed, highCarb, notSure }

enum MealFeeling { meh, good, superFeeling }

/// Öğün kaydı detay / düzenleme — meal card’dan açılır.
final class MealDetailView extends StatefulWidget {
  const MealDetailView({this.mealId, this.initialEatenAt, super.key});

  final String? mealId;
  final DateTime? initialEatenAt;

  @override
  State<MealDetailView> createState() => _MealDetailViewState();
}

class _MealDetailViewState extends State<MealDetailView>
    with MealDetailViewMixin {
  @override
  void initState() {
    super.initState();
    initMealDetail();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorBodyPageBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 56,
                width: double.infinity,
                child: _MealDetailHeader(),
              ),
              Expanded(
                child: loading
                    ? const Center(child: AppLoading())
                    : loadError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            loadError!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.notificationsEmptySubtitle,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          children: [
                            _MealTimeCard(
                              label: mealTimeLabel(context),
                              onEdit: onMealTimeEditTapped,
                            ),
                            const SizedBox(height: 12),
                            _MealOrSnackCard(
                              selected: mealKind,
                              onSelected: onMealKindSelected,
                            ),
                            const SizedBox(height: 12),
                            _DietTypeCard(
                              selected: dietChoice,
                              onSelected: onDietSelected,
                            ),
                            const SizedBox(height: 12),
                            _FeelingCard(
                              selected: feeling,
                              onSelected: onFeelingSelected,
                            ),
                            const SizedBox(height: 12),
                            _NotesCard(controller: notesController),
                          ],
                        ),
                      ),
              ),
              _SaveBar(
                bottomInset: bottom,
                saving: saving,
                onSave: loading || loadError != null ? null : onSaveTapped,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _MealDetailHeader extends StatelessWidget {
  const _MealDetailHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Material(
            color: ColorName.colorWhite,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.pop(),
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Transform.rotate(
                    angle: math.pi,
                    child: Assets.icons.solarAltArrowLeftLinear.svg(),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'meal_detail.title'.tr(),
              style: AppTextStyles.bodyHistoryTitle,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

final class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.mealDetailSectionTitle);
  }
}

final class _MealTimeCard extends StatelessWidget {
  const _MealTimeCard({required this.label, required this.onEdit});

  final String label;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              'meal_detail.meal_time'.tr(),
              style: AppTextStyles.mealDetailRowLabel,
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTextStyles.mealDetailTimeValue),
                const SizedBox(width: 6),
                AppImages.solarPenBold1.image(
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _MealOrSnackCard extends StatelessWidget {
  const _MealOrSnackCard({required this.selected, required this.onSelected});

  final MealKind? selected;
  final ValueChanged<MealKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('meal_detail.meal_or_snack'.tr()),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _KindTile(
                  label: 'meal_detail.kind_meal'.tr(),
                  image: AppImages.orangeBellv2,
                  selected: selected == MealKind.meal,
                  onTap: () => onSelected(MealKind.meal),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KindTile(
                  label: 'meal_detail.kind_snack'.tr(),
                  image: AppImages.apple,
                  selected: selected == MealKind.snack,
                  onTap: () => onSelected(MealKind.snack),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _KindTile extends StatelessWidget {
  const _KindTile({
    required this.label,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final AppImageAsset image;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 100,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            decoration: BoxDecoration(
              color: ColorName.colorMealCream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                width: 2,
                color: selected
                    ? ColorName.colorMealPositive
                    : Colors.transparent,
              ),
            ),
            alignment: Alignment.center,
            child: image.image(width: 56, height: 56, fit: BoxFit.contain),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: FontFamily.sFProDisplay,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              height: 24 / 16,
              letterSpacing: 16 * -0.015,
              color: ColorName.colorTitle,
            ),
          ),
        ],
      ),
    );
  }
}

final class _DietTypeCard extends StatelessWidget {
  const _DietTypeCard({required this.selected, required this.onSelected});

  final MealDietChoice? selected;
  final ValueChanged<MealDietChoice> onSelected;

  static final _items =
      <
        ({
          MealDietChoice diet,
          String titleKey,
          String? subtitleKey,
          AppImageAsset image,
        })
      >[
        (
          diet: MealDietChoice.ketogenic,
          titleKey: 'meal_detail.diet_keto_title',
          subtitleKey: 'meal_detail.diet_keto_subtitle',
          image: AppImages.avacado,
        ),
        (
          diet: MealDietChoice.lowCarb,
          titleKey: 'meal_detail.diet_low_carb_title',
          subtitleKey: 'meal_detail.diet_low_carb_subtitle',
          image: AppImages.lowCarbv2,
        ),
        (
          diet: MealDietChoice.mixed,
          titleKey: 'meal_detail.diet_mixed_title',
          subtitleKey: 'meal_detail.diet_mixed_subtitle',
          image: AppImages.mixedv2,
        ),
        (
          diet: MealDietChoice.highCarb,
          titleKey: 'meal_detail.diet_high_carb_title',
          subtitleKey: 'meal_detail.diet_high_carb_subtitle',
          image: AppImages.highCarbv2,
        ),
        (
          diet: MealDietChoice.notSure,
          titleKey: 'meal_detail.diet_not_sure_title',
          subtitleKey: null,
          image: AppImages.notSurev2,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('meal_detail.diet_type'.tr()),
          const SizedBox(height: 16),
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            OnboardingOptionCard(
              title: _items[i].titleKey.tr(),
              subtitle: _items[i].subtitleKey?.tr(),
              subtitleMaxLines: 1,
              isSelected: selected == _items[i].diet,
              onTap: () => onSelected(_items[i].diet),
              style: OnboardingOptionCardStyle(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(12),
                gap: 10,
                borderWidth: 2,

                unselectedBorderColor: ColorName.colorBlack.withValues(
                  alpha: 0.05,
                ),
                selectedBorderColor: ColorName.colorOptionSelected,
                selectedBackgroundColor: ColorName.colorOptionSelected
                    .withValues(alpha: 0.08),
                iconSize: 40,
                radioSize: 24,
              ),
              icon: Transform.flip(
                flipX: _items[i].diet == MealDietChoice.ketogenic,
                child: _items[i].image.image(
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

final class _FeelingCard extends StatelessWidget {
  const _FeelingCard({required this.selected, required this.onSelected});

  final MealFeeling selected;
  final ValueChanged<MealFeeling> onSelected;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('meal_detail.feeling_title'.tr()),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FeelingTile(
                  label: 'meal_detail.feeling_meh'.tr(),
                  image: AppImages.mehv2,
                  selected: selected == MealFeeling.meh,
                  onTap: () => onSelected(MealFeeling.meh),
                ),
              ),
              Expanded(
                child: _FeelingTile(
                  label: 'meal_detail.feeling_good'.tr(),
                  image: AppImages.goodv2,
                  selected: selected == MealFeeling.good,
                  onTap: () => onSelected(MealFeeling.good),
                ),
              ),
              Expanded(
                child: _FeelingTile(
                  label: 'meal_detail.feeling_super'.tr(),
                  image: AppImages.mealRecordEmoji,
                  selected: selected == MealFeeling.superFeeling,
                  onTap: () => onSelected(MealFeeling.superFeeling),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _FeelingTile extends StatelessWidget {
  const _FeelingTile({
    required this.label,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final AppImageAsset image;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          image.image(width: 56, height: 56, fit: BoxFit.contain),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: FontFamily.sFProDisplay,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              height: 24 / 16,
              letterSpacing: -0.5,
              color: selected
                  ? ColorName.colorTitle
                  : ColorName.colorSubtitle.withValues(alpha: 0.6),
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
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('meal_detail.notes_title'.tr()),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            style: AppTextStyles.mealDetailNoteText,
            decoration: InputDecoration(
              hintText: 'meal_detail.notes_hint'.tr(),
              hintStyle: AppTextStyles.mealDetailNoteHint,
              filled: true,
              fillColor: ColorName.colorBodyPageBg,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.bottomInset,
    required this.onSave,
    this.saving = false,
  });

  final double bottomInset;
  final VoidCallback? onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
      decoration: const BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: AppButton(
        label: 'meal_records_page.save_your_meal'.tr(),
        onPressed: saving ? null : onSave,
        decoration: AppButtonDecoration.primary(),
        showIcon: false,
      ),
    );
  }
}
