import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/dialog_handler.dart';
import 'package:fastingapp/core/dialogs/widgets/confirm_dialog.dart';
import 'package:fastingapp/core/dialogs/widgets/end_fast_dialog.dart';
import 'package:fastingapp/core/dialogs/widgets/fast_reward_dialog.dart';
import 'package:fastingapp/core/dialogs/widgets/fasting_time_dialog.dart';
import 'package:fastingapp/core/dialogs/widgets/goal_stepper_dialog.dart';
import 'package:fastingapp/core/dialogs/widgets/meal_date_picker_dialog.dart';
import 'package:fastingapp/core/dialogs/widgets/plan_change_while_fasting_dialog.dart';
import 'package:fastingapp/core/dialogs/widgets/sign_out_dialog.dart';
import 'package:fastingapp/core/dialogs/widgets/water_edit_dialog.dart';
import 'package:fastingapp/core/dialogs/widgets/weight_edit_dialog.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/domain/fasting/fasting_repository.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:fastingapp/generated/assets.gen.dart';
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

  /// Hesap silme onayı. `true` → onaylandı.
  Future<bool?> showDeleteAccount(BuildContext context) {
    return showNormalDialog<bool>(
      context: context,
      child: ConfirmDialog(
        icon: Assets.icons.solarTrashBinTrashBoldDuotone,
        title: 'profile.delete_account_title'.tr(),
        body: 'profile.delete_account_body'.tr(),
        confirmLabel: 'profile.delete_account_confirm'.tr(),
        cancelLabel: 'profile.delete_account_cancel'.tr(),
      ),
    );
  }

  /// Silme talebi bekleyen hesaba girişte geri alma sorusu. `true` → geri al.
  Future<bool?> showRestoreAccount(
    BuildContext context, {
    required DateTime scheduledFor,
  }) {
    final date = DateFormat.yMMMMd(
      context.locale.toLanguageTag(),
    ).format(scheduledFor.toLocal());
    return showNormalDialog<bool>(
      context: context,
      child: ConfirmDialog(
        icon: Assets.icons.solarTrashBinTrashBoldDuotone,
        title: 'auth.restore_account_title'.tr(),
        body: 'auth.restore_account_body'.tr(namedArgs: {'date': date}),
        confirmLabel: 'auth.restore_account_confirm'.tr(),
        cancelLabel: 'auth.restore_account_cancel'.tr(),
      ),
    );
  }

  /// Kilo dialogu; kullanıcının kg/lb tercihiyle açılır, değiştirilirse
  /// tercih sunucuya yazılır. Sonuç her zaman kg.
  Future<WeightEditResult?> showEditWeight(
    BuildContext context, {
    required double initialWeightKg,
  }) async {
    final trackers = getIt<TrackersRepository>();
    var unit = 'kg';
    try {
      unit = await trackers.weightUnit().timeout(const Duration(seconds: 2));
    } on Object {
      // Tercih okunamazsa kg.
    }
    if (!context.mounted) return null;
    final result = await showNormalDialog<WeightEditResult>(
      context: context,
      child: WeightEditDialog(
        initialWeightKg: initialWeightKg,
        initialUnit: unit == 'lb' ? WeightUnit.lb : WeightUnit.kg,
      ),
    );
    if (result != null && result.unit.name != unit) {
      unawaited(
        trackers.updateWeightUnit(result.unit.name).catchError((Object _) {}),
      );
    }
    return result;
  }

  Future<MealDatePickerResult?> showMealDatePicker(
    BuildContext context, {
    required DateTime initialDate,
    bool includeTime = false,
    Color? accentColor,
    int? maxDaysBack,
  }) {
    return showNormalDialog<MealDatePickerResult>(
      context: context,
      child: MealDatePickerDialog(
        initialDate: initialDate,
        includeTime: includeTime,
        accentColor: accentColor,
        maxDaysBack: maxDaysBack,
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

  /// Aktif oruç varken plan değiştirme. Barrier ile kapanırsa `null`.
  Future<PlanChangeWhileFastingAction?> showPlanChangeWhileFasting(
    BuildContext context,
  ) {
    return showNormalDialog<PlanChangeWhileFastingAction>(
      context: context,
      child: const PlanChangeWhileFastingDialog(),
    );
  }

  /// Molada (yemek penceresi bitmeden) oruç başlatma onayı. [remaining]
  /// molanın bitmesine kalan süre. `true` → kullanıcı onayladı.
  Future<bool?> showEarlyFastStart(
    BuildContext context, {
    required Duration remaining,
  }) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final left = hours > 0
        ? 'fasting_page.early_start_hm'.tr(args: ['$hours', '$minutes'])
        : 'fasting_page.early_start_m'.tr(args: ['${minutes.clamp(1, 59)}']);
    return showNormalDialog<bool>(
      context: context,
      child: ConfirmDialog(
        icon: Assets.icons.solarClockCircleLineDuotone,
        title: 'fasting_page.early_start_title'.tr(),
        body: 'fasting_page.early_start_body'.tr(args: [left]),
        confirmLabel: 'fasting_page.early_start_confirm'.tr(),
        cancelLabel: 'fasting_page.early_start_cancel'.tr(),
      ),
    );
  }

  /// Uzun oruç planı güvenlik uyarısı. `true` → kullanıcı onayladı.
  Future<bool?> showPlanSafetyAck(BuildContext context) {
    return showNormalDialog<bool>(
      context: context,
      child: ConfirmDialog(
        icon: Assets.icons.solarHeartLineDuotone,
        title: 'plans.safety_ack_title'.tr(),
        body: 'plans.safety_ack_body'.tr(),
        confirmLabel: 'plans.safety_ack_confirm'.tr(),
        cancelLabel: 'plans.safety_ack_cancel'.tr(),
      ),
    );
  }

  /// AI (sohbet / fotoğraf analizi) işleme rızası. `true` → onaylandı.
  Future<bool?> showAiProcessingConsent(BuildContext context) {
    return showNormalDialog<bool>(
      context: context,
      child: ConfirmDialog(
        icon: Assets.icons.solarChatDotsLineDuotone,
        title: 'ai_consent.title'.tr(),
        body: 'ai_consent.body'.tr(),
        confirmLabel: 'ai_consent.confirm'.tr(),
        cancelLabel: 'ai_consent.cancel'.tr(),
      ),
    );
  }

  /// Bitiş, planlanan bitişten çok sonra: yanlış saat girilmiş olabilir.
  /// `true` → bu saatle kaydet.
  Future<bool?> showLongOverrun(BuildContext context) {
    return showNormalDialog<bool>(
      context: context,
      child: ConfirmDialog(
        icon: Assets.icons.solarClockCircleLineDuotone,
        title: 'fasting_page.long_overrun_title'.tr(),
        body: 'fasting_page.long_overrun_body'.tr(),
        confirmLabel: 'fasting_page.long_overrun_confirm'.tr(),
        cancelLabel: 'fasting_page.long_overrun_cancel'.tr(),
      ),
    );
  }

  /// Öğün silme onayı. `true` → onaylandı.
  Future<bool?> showDeleteMeal(BuildContext context) {
    return showNormalDialog<bool>(
      context: context,
      child: ConfirmDialog(
        icon: Assets.icons.solarTrashBinTrashBoldDuotone,
        title: 'meal_detail.delete_title'.tr(),
        body: 'meal_detail.delete_body'.tr(),
        confirmLabel: 'meal_detail.delete_confirm'.tr(),
        cancelLabel: 'meal_detail.delete_cancel'.tr(),
      ),
    );
  }

  /// Uyku kaydı: yatış + kalkış saati.
  /// Meydan okumadan ayrıl. `true` → ayrıl.
  Future<bool?> showLeaveChallenge(BuildContext context) {
    return showNormalDialog<bool>(
      context: context,
      child: ConfirmDialog(
        icon: Assets.icons.solarLogout2LineDuotone,
        title: 'home.challenge_leave_title'.tr(),
        body: 'home.challenge_leave_body'.tr(),
        confirmLabel: 'home.challenge_leave'.tr(),
        cancelLabel: 'common.cancel'.tr(),
      ),
    );
  }

  /// Kilo kaydını sil. `true` → sil.
  Future<bool?> showDeleteWeight(BuildContext context) {
    return showNormalDialog<bool>(
      context: context,
      child: ConfirmDialog(
        icon: Assets.icons.solarTrashBinTrashBoldDuotone,
        title: 'body_history.delete_title'.tr(),
        body: 'body_history.delete_body'.tr(),
        confirmLabel: 'fasting_history_page.entry_delete'.tr(),
        cancelLabel: 'common.cancel'.tr(),
      ),
    );
  }

  /// Geçmiş oruç kaydını sil. `true` → sil.
  Future<bool?> showDeleteFast(BuildContext context) {
    return showNormalDialog<bool>(
      context: context,
      child: ConfirmDialog(
        icon: Assets.icons.solarTrashBinTrashBoldDuotone,
        title: 'fasting_history_page.delete_title'.tr(),
        body: 'fasting_history_page.delete_body'.tr(),
        confirmLabel: 'fasting_history_page.entry_delete'.tr(),
        cancelLabel: 'common.cancel'.tr(),
      ),
    );
  }

  /// Oruç bitince kazanımlar (seri, XP, seviye…).
  Future<void> showFastReward(
    BuildContext context, {
    required FinishFastResult result,
  }) {
    return showNormalDialog<void>(
      context: context,
      child: FastRewardDialog(result: result),
    );
  }

  /// Adım / uyku hedefi. Yeni değer ya da null.
  Future<int?> showGoalStepper(
    BuildContext context, {
    required String title,
    required int initial,
    required int min,
    required int max,
    required int step,
    required String Function(int value) format,
  }) {
    return showNormalDialog<int>(
      context: context,
      child: GoalStepperDialog(
        title: title,
        initial: initial,
        min: min,
        max: max,
        step: step,
        format: format,
        saveLabel: 'common.save'.tr(),
      ),
    );
  }

  /// Şartlar / gizlilik güncellendi. `true` → kabul.
  Future<bool?> showLegalUpdate(BuildContext context) {
    return showNormalDialog<bool>(
      context: context,
      child: ConfirmDialog(
        icon: Assets.icons.solarVerifiedCheckBold,
        title: 'legal_update.title'.tr(),
        body: 'legal_update.body'.tr(),
        confirmLabel: 'legal_update.accept'.tr(),
        cancelLabel: 'legal_update.later'.tr(),
      ),
    );
  }

  /// Uyku kaydına dokununca: `true` sil, `false` düzenle, null vazgeç.
  Future<bool?> showSleepEntryActions(BuildContext context) {
    return showNormalDialog<bool>(
      context: context,
      child: ConfirmDialog(
        icon: Assets.icons.solarPen2LineDuotone,
        title: 'sleep_page.entry_title'.tr(),
        body: 'sleep_page.entry_body'.tr(),
        confirmLabel: 'sleep_page.entry_delete'.tr(),
        cancelLabel: 'sleep_page.entry_edit'.tr(),
      ),
    );
  }

  /// Sessiz saatler (bildirim gönderilmez): başlangıç / bitiş.
  Future<FastingTimeResult?> showQuietHours(
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
        titleKey: 'notification_settings.quiet_hours',
        startLabelKey: 'notification_settings.quiet_start',
        endLabelKey: 'notification_settings.quiet_end',
      ),
    );
  }

  Future<FastingTimeResult?> showSleepTime(
    BuildContext context, {
    required int bedHour,
    required int bedMinute,
    required int wakeHour,
    required int wakeMinute,
  }) {
    return showNormalDialog<FastingTimeResult>(
      context: context,
      child: FastingTimeDialog(
        initialStartHour: bedHour,
        initialStartMinute: bedMinute,
        initialEndHour: wakeHour,
        initialEndMinute: wakeMinute,
        titleKey: 'sleep_page.log_title',
        startLabelKey: 'sleep_page.bedtime',
        endLabelKey: 'sleep_page.wakeup',
      ),
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
