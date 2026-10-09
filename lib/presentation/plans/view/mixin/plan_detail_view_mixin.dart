part of '../plan_detail_view.dart';

mixin PlanDetailViewMixin on State<PlanDetailView> {
  late PlanDetailArgs args;
  late int eatStartHour;
  late int eatStartMinute;
  late int eatHours;
  late int eatEndHour;
  late int eatEndMinute;
  late int fastHours;
  late int ratioEatHours;

  /// Kullanıcı "Değiştir" ile yemek penceresini seçti mi.
  bool windowChanged = false;

  void initPlanDetail(PlanDetailArgs detailArgs) {
    args = detailArgs;
    eatStartHour = detailArgs.eatStartHour;
    eatStartMinute = 0;
    eatHours = detailArgs.eatHours;
    eatEndHour = detailArgs.eatEndHour;
    eatEndMinute = 0;
    fastHours = detailArgs.fastHours;
    ratioEatHours = detailArgs.ratioEatHours;
  }

  String formatTime(int hour, int minute) {
    final h = hour % 24;
    final m = minute.clamp(0, 59);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Future<void> onChangeTapped() async {
    final result = await AppDialogs.instance.showFastingTime(
      context,
      startHour: eatStartHour,
      startMinute: eatStartMinute,
      endHour: eatEndHour,
      endMinute: eatEndMinute,
    );
    if (!mounted || result == null) return;

    final startTotal = result.startHour * 60 + result.startMinute;
    var endTotal = result.endHour * 60 + result.endMinute;
    if (endTotal <= startTotal) endTotal += 24 * 60;
    final windowMinutes = endTotal - startTotal;

    setState(() {
      windowChanged = true;
      eatStartHour = result.startHour;
      eatStartMinute = result.startMinute;
      eatEndHour = result.endHour;
      eatEndMinute = result.endMinute;
      eatHours = (windowMinutes / 60).round().clamp(1, 23);
    });
  }

  /// Seçim plan sekmesine döner; kaydı (`PUT /plans/current`) orası yapar.
  void onStartPlanTapped() {
    context.pop(
      PlanSelection(
        plan: args.plan,
        eatStart: windowChanged
            ? formatTime(eatStartHour, eatStartMinute)
            : null,
        eatEnd: windowChanged ? formatTime(eatEndHour, eatEndMinute) : null,
      ),
    );
  }
}
