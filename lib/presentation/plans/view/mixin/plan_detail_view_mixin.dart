part of '../plan_detail_view.dart';

mixin PlanDetailViewMixin on State<PlanDetailView> {
  late PlanDetailArgs args;
  late int eatStartHour;
  late int eatStartMinute;
  late int eatMinutes;
  late int fastMinutes;
  late int eatEndHour;
  late int eatEndMinute;

  /// Kullanıcı "Değiştir" ile yemek penceresini seçti mi.
  bool windowChanged = false;

  /// Planın kendi penceresi. Kullanıcı bunu değiştirince özel pencere olur.
  int _baselineStartMinutes = 0;
  int _baselineEndMinutes = 0;

  /// Katalog geç gelip kullanıcının seçtiği saatin üzerine yazmasın.
  int _scheduleToken = 0;

  double get eatShare {
    final total = eatMinutes + fastMinutes;
    if (total <= 0) return 0;
    return eatMinutes / total;
  }

  void initPlanDetail(PlanDetailArgs detailArgs) {
    args = detailArgs;
    // Detay önceden yüklendiyse sayfa doğru pencereyle açılır (sonradan
    // katalog gelip saatler zıplamaz).
    final cached = PlanCatalogRepository.instance?.cachedDetail(
      args.plan.planCode,
    );
    _apply(_resolve(detail: cached));
  }

  /// Katalog listesi ve plan detayı gelince saati gerçek süreye çeker.
  /// Kullanıcı pencereyi kendisi değiştirdiyse üzerine yazılmaz.
  Future<void> loadCatalogSchedule() async {
    final repo = PlanCatalogRepository.instance;
    if (repo == null) return;
    final token = _scheduleToken;
    if (repo.isLoaded && repo.cachedDetail(args.plan.planCode) != null) return;
    try {
      await repo.ensureLoaded();
      final detail = await repo.detail(args.plan.planCode);
      if (!mounted || windowChanged || token != _scheduleToken) return;
      setState(() {
        if (windowChanged || token != _scheduleToken) return;
        _apply(_resolve(detail: detail));
      });
    } on Object {
      // Karttan hesaplanan pencere durur.
    }
  }

  ResolvedPlanSchedule _resolve({PlanCatalogDetail? detail}) {
    final repo = PlanCatalogRepository.instance;
    final current = getIt.isRegistered<FastingSessionCubit>()
        ? getIt<FastingSessionCubit>().state.plan
        : null;
    return resolvePlanSchedule(
      fallbackFastHours: args.fastHours,
      fallbackEatHours: args.eatHours,
      cardTiming: args.plan.timing,
      planCode: args.plan.planCode,
      catalog: repo?.entry(args.plan.planCode),
      detail: detail,
      currentPlanCode: current?.planCode,
      currentTiming: current?.timing,
      currentEatStart: current?.eatWindow?.start,
      currentEatEnd: current?.eatWindow?.end,
    );
  }

  void _apply(ResolvedPlanSchedule schedule) {
    eatMinutes = schedule.eatMinutes;
    fastMinutes = schedule.fastMinutes;
    eatStartHour = schedule.startHour;
    eatStartMinute = schedule.startMinute;
    eatEndHour = schedule.endHour;
    eatEndMinute = schedule.endMinute;
    _baselineStartMinutes = schedule.startMinutes;
    _baselineEndMinutes = schedule.endMinutes;
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

    final chosenStart = result.startHour * 60 + result.startMinute;
    final chosenEnd = result.endHour * 60 + result.endMinute;
    final shownStart = eatStartHour * 60 + eatStartMinute;
    final shownEnd = eatEndHour * 60 + eatEndMinute;
    final startMoved = chosenStart != shownStart;
    final endMoved = chosenEnd != shownEnd;
    // Tek taraf kayarsa pencere aynı uzunlukta kayar. İkisi birden
    // değiştiyse seçilen aralık olduğu gibi uygulanır.
    final int newStart;
    final int newEnd;
    if (startMoved && endMoved) {
      newStart = chosenStart;
      newEnd = chosenEnd;
    } else if (endMoved) {
      newEnd = chosenEnd;
      final shifted = chosenEnd - eatMinutes;
      newStart = shifted < 0 ? shifted + 24 * 60 : shifted;
    } else {
      newStart = chosenStart;
      newEnd = (chosenStart + eatMinutes) % (24 * 60);
    }
    var duration = newEnd - newStart;
    if (duration <= 0) duration += 24 * 60;
    if (duration <= 0 || duration >= 24 * 60) return;

    setState(() {
      _scheduleToken++;
      eatMinutes = duration;
      fastMinutes = 24 * 60 - duration;
      eatStartHour = newStart ~/ 60;
      eatStartMinute = newStart % 60;
      eatEndHour = newEnd ~/ 60;
      eatEndMinute = newEnd % 60;
      windowChanged =
          newStart != _baselineStartMinutes || newEnd != _baselineEndMinutes;
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
