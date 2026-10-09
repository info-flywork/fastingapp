import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/dialogs/widgets/plan_change_while_fasting_dialog.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:fastingapp/core/utils/extensions/future_extensions.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_cubit.dart';
import 'package:flutter/material.dart';

/// Plan kaydı: aktif oruçta diyalog → loading → snackbar.
/// `true` = başarıyla uygulandı.
Future<bool> applyPlanChange({
  required BuildContext context,
  required FastingSessionCubit session,
  required String planCode,
  String? timing,
  String? eatStart,
  String? eatEnd,
}) async {
  var whileFasting = false;
  var restartSame = false;
  if (session.state.isFasting) {
    final action = await AppDialogs.instance.showPlanChangeWhileFasting(
      context,
    );
    if (!context.mounted) return false;
    if (action == null || action == PlanChangeWhileFastingAction.reject) {
      return false;
    }
    whileFasting = true;
    restartSame = action == PlanChangeWhileFastingAction.restartWithSameData;
  }

  final Future<bool> apply = whileFasting
      ? session.changePlanWhileFasting(
          planCode: planCode,
          timing: timing,
          eatStart: eatStart,
          eatEnd: eatEnd,
          restartWithSameData: restartSame,
        )
      : session.changePlan(
          planCode: planCode,
          timing: timing,
          eatStart: eatStart,
          eatEnd: eatEnd,
        );
  final changed = await apply.withLoading(context);
  if (!context.mounted) return false;

  final error = session.state.errorMessage;
  if (!changed) {
    if (error != null) {
      AppSnackbar.show(
        context: context,
        text: error,
        type: SnackBarType.failure,
      );
    }
    return false;
  }

  AppSnackbar.show(
    context: context,
    text: restartSame
        ? 'plans.plan_restarted'.tr()
        : 'plans.plan_saved'.tr(),
    type: SnackBarType.success,
  );
  return true;
}
