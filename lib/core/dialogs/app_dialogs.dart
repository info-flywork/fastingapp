import 'package:fastingapp/core/dialogs/dialog_handler.dart';
import 'package:fastingapp/core/dialogs/widgets/sign_out_dialog.dart';
import 'package:fastingapp/core/dialogs/widgets/water_edit_dialog.dart';
import 'package:fastingapp/core/dialogs/widgets/weight_edit_dialog.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:flutter/material.dart';

/// Tüm dialog'ların tek giriş noktası (singleton). Feature katmanında
/// doğrudan `showDialog` kullanılmaz. (Doküman 9.3)
final class AppDialogs extends DialogHandler {
  AppDialogs._init();

  static final AppDialogs _instance = AppDialogs._init();

  static AppDialogs get instance => _instance;

  Future<void> showSignOut(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    return showNormalDialog<void>(
      context: context,
      child: SignOutDialog(onConfirm: onConfirm),
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

  Future<WaterValueEditResult?> showEditWaterValue(
    BuildContext context, {
    required String titleKey,
    required String subtitleKey,
    required int initialValueMl,
    required WaterVolumeUnit initialUnit,
    required AssetGenImage headerImage,
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
}
