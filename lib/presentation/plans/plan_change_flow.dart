import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/dialogs/widgets/plan_change_while_fasting_dialog.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:fastingapp/core/utils/extensions/future_extensions.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/domain/fasting/plan_catalog_repository.dart';
import 'package:fastingapp/domain/fasting/plan_safety.dart';
import 'package:fastingapp/domain/fasting/weekly_schedule.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_cubit.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:fastingapp/presentation/plans/plans_catalog.dart';
import 'package:fastingapp/presentation/plans/view/weekly_plan_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Plan kaydı: aktif oruçta diyalog → loading → snackbar.
/// `true` = başarıyla uygulandı.
Future<bool> applyPlanChange({
  required BuildContext context,
  required FastingSessionCubit session,
  required String planCode,
  String? timing,
  String? eatStart,
  String? eatEnd,
  List<WeeklyDay>? weeklySchedule,
}) async {
  // Uzun planlar: sunucu `safetyAcknowledged` ister; uyarı önce gösterilir.
  await getIt<PlanCatalogRepository>().ensureLoaded();
  if (!context.mounted) return false;
  final needsAck = planRequiresSafetyAck(planCode);
  if (needsAck) {
    final ok = await AppDialogs.instance.showPlanSafetyAck(context);
    if (!context.mounted || ok != true) return false;
  }

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
          weeklySchedule: weeklySchedule,
          safetyAcknowledged: needsAck,
          restartWithSameData: restartSame,
        )
      : session.changePlan(
          planCode: planCode,
          timing: timing,
          eatStart: eatStart,
          eatEnd: eatEnd,
          weeklySchedule: weeklySchedule,
          safetyAcknowledged: needsAck,
        );
  final changed = await apply.withLoading(
    context,
    showAfter: const Duration(milliseconds: 300),
  );
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
    text: restartSame ? 'plans.plan_restarted'.tr() : 'plans.plan_saved'.tr(),
    type: SnackBarType.success,
  );
  return true;
}

/// Haftalık plan: önce premium (paywall), sonra gün seçimi sayfası, sonra
/// [applyPlanChange]. Aynı plandaysa mevcut program açılır. `true` =
/// uygulandı.
Future<bool> openWeeklyPlan({
  required BuildContext context,
  required FastingSessionCubit session,
  required PlansCardData plan,
}) async {
  final revenueCat = getIt<RevenueCatService>();
  if (plan.isLocked && !revenueCat.isPremium.value) {
    if (!await revenueCat.presentPaywall() || !context.mounted) return false;
  }
  final current = session.state.plan;
  final repo = getIt<PlanCatalogRepository>();
  await repo.ensureLoaded();
  final detail = await repo.detail(plan.planCode);
  final saved = current?.planCode == plan.planCode
      ? current?.weeklySchedule
      : null;
  final template = detail?.weeklyTemplate;
  if (!context.mounted) return false;
  final days = await context.pushNamed<List<WeeklyDay>>(
    RoutePaths.weeklyPlanDetail.name,
    extra: WeeklyPlanDetailArgs(
      plan: plan,
      current: saved != null && saved.length == 7
          ? saved
          : template != null && template.length == 7
          ? template
          : null,
    ),
  );
  if (days == null || !context.mounted) return false;
  return applyPlanChange(
    context: context,
    session: session,
    planCode: plan.planCode,
    weeklySchedule: days,
  );
}
