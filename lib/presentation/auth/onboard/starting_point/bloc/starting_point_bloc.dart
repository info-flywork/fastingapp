import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'starting_point_event.dart';
part 'starting_point_state.dart';

final class StartingPointBloc
    extends Bloc<StartingPointEvent, StartingPointState> {
  StartingPointBloc() : super(const StartingPointState()) {
    on<StartingPointWeightChanged>(_onWeight);
    on<StartingPointGoalWeightChanged>(_onGoalWeight);
    on<StartingPointHeightChanged>(_onHeight);
    on<StartingPointAgeChanged>(_onAge);
  }

  void _onWeight(
    StartingPointWeightChanged event,
    Emitter<StartingPointState> emit,
  ) {
    final weight = event.value.clamp(30.0, 300.0);
    final goal = state.goalWeightKg > weight ? weight : state.goalWeightKg;
    emit(state.copyWith(weightKg: weight, goalWeightKg: goal));
  }

  void _onGoalWeight(
    StartingPointGoalWeightChanged event,
    Emitter<StartingPointState> emit,
  ) {
    // Hedef, mevcut kiloyu geçemez.
    final maxGoal = state.weightKg;
    emit(
      state.copyWith(
        goalWeightKg: event.value.clamp(30.0, maxGoal),
      ),
    );
  }

  void _onHeight(
    StartingPointHeightChanged event,
    Emitter<StartingPointState> emit,
  ) {
    emit(state.copyWith(heightCm: event.value.clamp(100, 250)));
  }

  void _onAge(
    StartingPointAgeChanged event,
    Emitter<StartingPointState> emit,
  ) {
    emit(state.copyWith(age: event.value.clamp(13, 100)));
  }
}
