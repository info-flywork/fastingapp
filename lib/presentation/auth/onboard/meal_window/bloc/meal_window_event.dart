part of 'meal_window_bloc.dart';

sealed class MealWindowEvent extends Equatable {
  const MealWindowEvent();

  @override
  List<Object?> get props => [];
}

final class MealWindowStartHourChanged extends MealWindowEvent {
  const MealWindowStartHourChanged(this.hour);

  final int hour;

  @override
  List<Object?> get props => [hour];
}

final class MealWindowStartMinuteChanged extends MealWindowEvent {
  const MealWindowStartMinuteChanged(this.minute);

  final int minute;

  @override
  List<Object?> get props => [minute];
}

final class MealWindowEndHourChanged extends MealWindowEvent {
  const MealWindowEndHourChanged(this.hour);

  final int hour;

  @override
  List<Object?> get props => [hour];
}

final class MealWindowEndMinuteChanged extends MealWindowEvent {
  const MealWindowEndMinuteChanged(this.minute);

  final int minute;

  @override
  List<Object?> get props => [minute];
}
