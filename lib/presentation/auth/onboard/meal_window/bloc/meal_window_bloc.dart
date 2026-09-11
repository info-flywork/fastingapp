import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'meal_window_event.dart';
part 'meal_window_state.dart';

final class MealWindowBloc extends Bloc<MealWindowEvent, MealWindowState> {
  MealWindowBloc()
      : super(
          const MealWindowState(
            startHour: 7,
            startMinute: 0,
            endHour: 19,
            endMinute: 0,
          ),
        ) {
    on<MealWindowStartHourChanged>(_onStartHour);
    on<MealWindowStartMinuteChanged>(_onStartMinute);
    on<MealWindowEndHourChanged>(_onEndHour);
    on<MealWindowEndMinuteChanged>(_onEndMinute);
  }

  void _onStartHour(
    MealWindowStartHourChanged event,
    Emitter<MealWindowState> emit,
  ) {
    emit(state.copyWith(startHour: event.hour));
  }

  void _onStartMinute(
    MealWindowStartMinuteChanged event,
    Emitter<MealWindowState> emit,
  ) {
    emit(state.copyWith(startMinute: event.minute));
  }

  void _onEndHour(
    MealWindowEndHourChanged event,
    Emitter<MealWindowState> emit,
  ) {
    emit(state.copyWith(endHour: event.hour));
  }

  void _onEndMinute(
    MealWindowEndMinuteChanged event,
    Emitter<MealWindowState> emit,
  ) {
    emit(state.copyWith(endMinute: event.minute));
  }
}
