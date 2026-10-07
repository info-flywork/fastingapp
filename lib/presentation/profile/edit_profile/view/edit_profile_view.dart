import 'dart:io';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/bottom_sheets/app_bottom_sheets.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:fastingapp/core/utils/extensions/future_extensions.dart';
import 'package:fastingapp/domain/auth/auth_exception.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/about_you/bloc/about_you_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/about_you/gender_options_catalog.dart';
import 'package:fastingapp/presentation/auth/onboard/diet/bloc/diet_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/diet/diet_options_catalog.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/bloc/fasting_plan_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/fasting_plan_options_catalog.dart';
import 'package:fastingapp/presentation/auth/onboard/food_loves/bloc/food_loves_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/food_loves/food_loves_options_catalog.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/bloc/food_skips_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/food_skips_options_catalog.dart';
import 'package:fastingapp/presentation/auth/onboard/goal/bloc/goal_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/goal/goal_options_catalog.dart';
import 'package:fastingapp/presentation/profile/edit_profile/view/edit_height_view.dart';
import 'package:fastingapp/presentation/profile/view/widgets/profile_menu_card.dart';
import 'package:fastingapp/presentation/profile/view/widgets/profile_section.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

part 'mixin/edit_profile_view_mixin.dart';
part 'widgets/edit_profile_chips_row.dart';
part 'widgets/edit_profile_header.dart';

/// Profil düzenleme ekranı.
final class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView>
    with EditProfileViewMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorName.colorProfileBack,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            EditProfileHeader(
              initials: 'AE',
              photoPath: photoPath,
              onBack: onBack,
              onChangePhoto: onChangePhoto,
            ),
            const SizedBox(height: 24),
            ProfileSection(
              title: 'profile.basic_information'.tr(),
              child: ProfileMenuCard(
                children: [
                  ProfileMenuRow(
                    icon: Assets.icons.solarPen2LineDuotone,
                    title: 'profile.name'.tr(),
                    titleStyle: AppTextStyles.editProfileLabel,
                    trailing: Text(
                      displayName,
                      style: AppTextStyles.editProfileValue,
                    ),
                    onTap: onEditName,
                  ),
                  ProfileMenuRow(
                    icon: Assets.icons.solarTargetLineDuotone,
                    title: 'profile.fasting_target'.tr(),
                    titleStyle: AppTextStyles.editProfileLabel,
                    trailing: Text(
                      GoalOptionsCatalog.titleKeyFor(fastingTarget).tr(),
                      style: AppTextStyles.editProfileValue,
                    ),
                    onTap: onEditFastingTarget,
                  ),
                  ProfileMenuRow(
                    icon: Assets.icons.solarWeigherLineDuotone,
                    title: 'profile.weight_kg'.tr(),
                    titleStyle: AppTextStyles.editProfileLabel,
                    trailing: Text(
                      _formatWeight(weightKg),
                      style: AppTextStyles.editProfileValue,
                    ),
                    onTap: onEditWeight,
                  ),
                  ProfileMenuRow(
                    icon: Assets.icons.healthiconsHeightOutline,
                    title: 'profile.height_cm'.tr(),
                    titleStyle: AppTextStyles.editProfileLabel,
                    trailing: Text(
                      '$heightCm',
                      style: AppTextStyles.editProfileValue,
                    ),
                    onTap: onEditHeight,
                  ),
                  ProfileMenuRow(
                    icon: Assets.icons.icons8Gender,
                    title: 'profile.gender'.tr(),
                    titleStyle: AppTextStyles.editProfileLabel,
                    trailing: Text(
                      GenderOptionsCatalog.titleKeyFor(gender).tr(),
                      style: AppTextStyles.editProfileValue,
                    ),
                    onTap: onEditGender,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ProfileSection(
              title: 'profile.diet_information'.tr(),
              child: ProfileMenuCard(
                children: [
                  ProfileMenuRow(
                    icon: Assets.icons.solarCart3LineDuotone,
                    title: 'profile.diet_type'.tr(),
                    titleStyle: AppTextStyles.editProfileLabel,
                    trailing: Text(
                      DietOptionsCatalog.titleKeyFor(dietType).tr(),
                      style: AppTextStyles.editProfileValue,
                    ),
                    onTap: onEditDietType,
                  ),
                  EditProfileChipsRow(
                    icon: Assets.icons.hugeiconsBanana,
                    title: 'profile.preferred_foods'.tr(),
                    chips: preferredFoods
                        .map((e) => FoodLovesOptionsCatalog.titleKeyFor(e).tr())
                        .toList(),
                    onTap: onEditPreferredFoods,
                  ),
                  EditProfileChipsRow(
                    icon: Assets.icons.solarDislikeLineDuotone,
                    title: 'profile.skipped_foods'.tr(),
                    chips: skippedFoods
                        .map((e) => FoodSkipsOptionsCatalog.titleKeyFor(e).tr())
                        .toList(),
                    variant: EditProfileChipVariant.negative,
                    onTap: onEditSkippedFoods,
                  ),
                  ProfileMenuRow(
                    icon: Assets.icons.solarClockCircleLineDuotone,
                    title: 'profile.fasting_plan'.tr(),
                    titleStyle: AppTextStyles.editProfileLabel,
                    trailing: Text(
                      FastingPlanOptionsCatalog.titleKeyFor(fastingPlan).tr(),
                      style: AppTextStyles.editProfileValue,
                    ),
                    onTap: onEditFastingPlan,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ProfileDangerCard(
              icon: Assets.icons.solarTrashBinTrashBoldDuotone,
              label: 'profile.delete_account'.tr(),
              onTap: onDeleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}
