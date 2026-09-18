part of '../meal_detail_view.dart';

mixin MealDetailViewMixin on State<MealDetailView> {
  late DateTime mealAt;
  MealKind? mealKind;
  MealDietChoice? dietChoice;
  late MealFeeling feeling;
  late final TextEditingController notesController;

  void initMealDetail() {
    mealAt = DateTime.now();
    mealKind = null;
    dietChoice = null;
    feeling = MealFeeling.superFeeling;
    notesController = TextEditingController();
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  String mealTimeLabel(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(mealAt);
    final time = DateFormat.jm(context.locale.toString()).format(mealAt);
    if (DateUtils.isSameDay(day, today)) {
      return '${'meal_records_page.today'.tr()}, $time';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (DateUtils.isSameDay(day, yesterday)) {
      return '${'meal_records_page.yesterday'.tr()}, $time';
    }
    return '${DateFormat.MMMd(context.locale.toString()).format(mealAt)}, '
        '$time';
  }

  Future<void> onMealTimeEditTapped() async {
    final result = await AppDialogs.instance.showMealDatePicker(
      context,
      initialDate: mealAt,
      includeTime: true,
    );
    if (result == null || !mounted) return;
    setState(() => mealAt = result.date);
  }

  void onMealKindSelected(MealKind kind) {
    setState(() => mealKind = kind);
  }

  void onDietSelected(MealDietChoice diet) {
    setState(() => dietChoice = diet);
  }

  void onFeelingSelected(MealFeeling value) {
    setState(() => feeling = value);
  }

  void onSaveTapped() {
    context.pop();
  }
}
