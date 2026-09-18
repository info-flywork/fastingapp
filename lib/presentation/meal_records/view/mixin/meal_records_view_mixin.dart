part of '../meal_records_view.dart';

mixin MealRecordsViewMixin on State<MealRecordsView> {
  late DateTime selectedDate;

  void initMealRecords() {
    selectedDate = DateUtils.dateOnly(DateTime.now());
  }

  /// Mock: bugün ve dün kayıtlı; diğer günler boş.
  bool get hasMealsForSelectedDate {
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    return DateUtils.isSameDay(selectedDate, today) ||
        DateUtils.isSameDay(selectedDate, yesterday);
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
  }

  void onMealCardTapped() {
    context.pushNamed(RoutePaths.mealDetail.name);
  }

  void onSaveMealTapped() {
    context.pushNamed(RoutePaths.mealDetail.name);
  }
}
