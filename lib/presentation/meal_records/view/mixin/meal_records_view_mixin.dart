part of '../meal_records_view.dart';

mixin MealRecordsViewMixin on State<MealRecordsView> {
  late DateTime selectedDate;
  List<MealRecord> meals = const [];
  bool loading = true;

  MealsRepository get _meals => getIt<MealsRepository>();

  void initMealRecords() {
    selectedDate = DateUtils.dateOnly(DateTime.now());
    unawaited(_loadMeals());
  }

  bool get hasMealsForSelectedDate => !loading && meals.isNotEmpty;

  Future<void> _loadMeals() async {
    setState(() => loading = true);
    try {
      final items = await _meals.listForDay(selectedDate);
      if (mounted) setState(() => meals = items);
    } on Object {
      if (mounted) setState(() => meals = const []);
    } finally {
      if (mounted) setState(() => loading = false);
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
