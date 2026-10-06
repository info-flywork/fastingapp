import 'package:fastingapp/core/dialogs/dialog_handler.dart';
import 'package:fastingapp/core/dialogs/widgets/end_fast_dialog.dart';
import 'package:fastingapp/core/dialogs/widgets/fasting_time_dialog.dart';
import 'package:fastingapp/core/dialogs/widgets/meal_date_picker_dialog.dart';
import 'package:fastingapp/core/dialogs/widgets/sign_out_dialog.dart';
import 'package:fastingapp/core/dialogs/widgets/water_edit_dialog.dart';
import 'package:fastingapp/core/dialogs/widgets/weight_edit_dialog.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:flutter/material.dart';

/// Tüm dialog'ların tek giriş noktası (singleton). Feature katmanında
/// doğrudan `showDialog` kullanılmaz. (Doküman 9.3)
final class AppDialogs extends DialogHandler {
  AppDialogs._init();

  static final AppDialogs _instance = AppDialogs._init();

  static AppDialogs get instance => _instance;

  /// Çıkış onayı. `true` → onaylandı.
  Future<bool?> showSignOut(BuildContext context) {
    return showNormalDialog<bool>(
      context: context,
      child: const SignOutDialog(),
    );
  }

  Future<WeightEditResult?> showEditWeight(
    BuildContext context, {
    required double initialWeightKg,
  }) {
    return showNormalDialog<WeightEditResult>(
      context: context,
      child: WeightEditDialog(initialWeightKg: initialWeightKg),
    );
  }

  Future<MealDatePickerResult?> showMealDatePicker(
    BuildContext context, {
    required DateTime initialDate,
    bool includeTime = false,
  }) {
    return showNormalDialog<MealDatePickerResult>(
      context: context,
      child: MealDatePickerDialog(
        initialDate: initialDate,
        includeTime: includeTime,
      ),
    );
  }

  Future<WaterValueEditResult?> showEditWaterValue(
    BuildContext context, {
    required String titleKey,
    required String subtitleKey,
    required int initialValueMl,
    required WaterVolumeUnit initialUnit,
    required AppImageAsset headerImage,
  }) {
    return showNormalDialog<WaterValueEditResult>(
      context: context,
      child: WaterValueEditDialog(
        titleKey: titleKey,
        subtitleKey: subtitleKey,
        initialValueMl: initialValueMl,
        initialUnit: initialUnit,
        headerImage: headerImage,
      ),
    );
  }

  Future<WaterUnitEditResult?> showEditWaterUnit(
    BuildContext context, {
    required WaterVolumeUnit initialUnit,
  }) {
    return showNormalDialog<WaterUnitEditResult>(
      context: context,
      child: WaterUnitEditDialog(initialUnit: initialUnit),
    );
  }

  Future<bool?> showEndFast(BuildContext context) {
    return showNormalDialog<bool>(
      context: context,
      child: const EndFastDialog(),
    );
  }

  Future<FastingTimeResult?> showFastingTime(
    BuildContext context, {
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) {
    return showNormalDialog<FastingTimeResult>(
      context: context,
      child: FastingTimeDialog(
        initialStartHour: startHour,
        initialStartMinute: startMinute,
        initialEndHour: endHour,
        initialEndMinute: endMinute,
      ),
    );
  }
}
