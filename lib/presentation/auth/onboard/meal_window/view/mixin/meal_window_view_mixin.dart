part of '../meal_window_view.dart';

mixin MealWindowViewMixin on State<MealWindowView> {
  void onBack() {
    context.pop();
  }

  void onStartHourChanged(int hour) {
    context.read<MealWindowBloc>().add(MealWindowStartHourChanged(hour));
  }

  void onStartMinuteChanged(int minute) {
    context.read<MealWindowBloc>().add(MealWindowStartMinuteChanged(minute));
  }

  void onEndHourChanged(int hour) {
    context.read<MealWindowBloc>().add(MealWindowEndHourChanged(hour));
  }

  void onEndMinuteChanged(int minute) {
    context.read<MealWindowBloc>().add(MealWindowEndMinuteChanged(minute));
  }

  void onContinue() {
    context.push(RoutePaths.buildingPlan.path);
  }
}
