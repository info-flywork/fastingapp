part of '../meal_records_view.dart';

mixin MealRecordsViewMixin on State<MealRecordsView> {
  late DateTime selectedDate;
  List<MealRecord> meals = const [];
  bool loading = true;

  MealsRepository get _meals => getIt<MealsRepository>();

  /// Yeni yükleme başlayınca artar: eski yüklemenin cevabı yenisini ezmesin.
  int _loadGen = 0;

  void initMealRecords() {
    selectedDate = DateUtils.dateOnly(DateTime.now());
    unawaited(_loadMeals());
  }

  bool get hasMealsForSelectedDate => !loading && meals.isNotEmpty;

  /// Bu gün daha önce görüldüyse iskelet gösterilmez: önbellek hemen
  /// çizilir, ağ yanıtı gelince yenilenir. Hata boş liste gibi gösterilmez.
  Future<void> _loadMeals() async {
    final gen = ++_loadGen;
    final date = selectedDate;
    // Yazmalar önbelleği yerinde günceller: kayıt / düzenleme sonrası dönüşte
    // liste beklemeden doğru.
    final cached = _meals.cachedDay(date);
    setState(() {
      meals = cached ?? const [];
      loading = cached == null;
    });
    try {
      final items = await _meals.listForDay(date);
      if (mounted && gen == _loadGen) setState(() => meals = items);
    } on Object catch (e) {
      if (mounted && gen == _loadGen && _meals.cachedDay(date) == null) {
        AppSnackbar.showError(context, e);
      }
    } finally {
      if (mounted && gen == _loadGen) setState(() => loading = false);
    }
  }

  String dateLabel(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    if (DateUtils.isSameDay(selectedDate, today)) {
      return 'meal_records_page.today'.tr();
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (DateUtils.isSameDay(selectedDate, yesterday)) {
      return 'meal_records_page.yesterday'.tr();
    }
    return DateFormat.MMMd(context.locale.toString()).format(selectedDate);
  }

  Future<void> onDateSelectorTapped() async {
    final result = await AppDialogs.instance.showMealDatePicker(
      context,
      initialDate: selectedDate,
    );
    if (result == null || !mounted) return;
    setState(() => selectedDate = DateUtils.dateOnly(result.date));
    unawaited(_loadMeals());
  }

  Future<void> onMealCardTapped(String mealId) async {
    await context.pushNamed(
      RoutePaths.mealDetail.name,
      extra: MealDetailArgs(mealId: mealId),
    );
    if (mounted) unawaited(_loadMeals());
  }

  Future<void> onSaveMealTapped() async {
    final initial = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      DateTime.now().hour,
      DateTime.now().minute,
    );
    await context.pushNamed(
      RoutePaths.mealDetail.name,
      extra: MealDetailArgs(initialEatenAt: initial),
    );
    if (mounted) unawaited(_loadMeals());
  }
}
