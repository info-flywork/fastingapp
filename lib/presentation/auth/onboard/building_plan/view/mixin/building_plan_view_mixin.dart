part of '../building_plan_view.dart';

mixin BuildingPlanViewMixin on State<BuildingPlanView> {
  List<String> get bodyChips => [
        'onboarding.building_chip_woman'.tr(),
        'onboarding.building_chip_weight'.tr(args: ['74']),
        'onboarding.building_chip_height'.tr(args: ['172']),
        'onboarding.building_chip_age'.tr(args: ['29']),
        'onboarding.building_chip_weight'.tr(args: ['64']),
      ];

  List<String> get lifestyleChips => [
        'onboarding.building_chip_no_onions'.tr(),
        'onboarding.building_chip_loves_chicken'.tr(),
        'onboarding.plan_16_8_title'.tr(),
        'onboarding.building_chip_first_if'.tr(),
        'onboarding.building_chip_special_target'.tr(),
      ];

  void onContinue() {
    context.push(RoutePaths.weightProjection.path);
  }
}
