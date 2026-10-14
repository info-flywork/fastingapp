import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'starting_point_event.dart';
part 'starting_point_state.dart';

final class StartingPointBloc
    extends Bloc<StartingPointEvent, StartingPointState> {
  /// [allowGoalAboveCurrent]: hedef kilo vermek değilse (alışkanlık, enerji…)
  /// hedef kilo mevcut kilonun üstünde olabilir (sunucu yalnızca
  /// `loseWeight`'te sınırlar).
  StartingPointBloc({this.allowGoalAboveCurrent = false})
    : super(const StartingPointState()) {
    on<StartingPointWeightChanged>(_onWeight);
    on<StartingPointGoalWeightChanged>(_onGoalWeight);
    on<StartingPointHeightChanged>(_onHeight);
    on<StartingPointAgeChanged>(_onAge);
  }

  final bool allowGoalAboveCurrent;

  /// Hedef kilo aralığı: alt sınır BMI 17.5 (sunucu `goal_bmi` ile en sonda
  /// reddediyordu), üst sınır kilo vermede mevcut kilo.
  double _clampGoal(
    double goal, {
    required double weight,
    required int height,
  }) {
    final max = allowGoalAboveCurrent ? 300.0 : weight;
    final min = math.min(StartingPointState.minGoalKgFor(height), max);
    return goal.clamp(math.max(30, min), max);
  }

  void _onWeight(
    StartingPointWeightChanged event,
    Emitter<StartingPointState> emit,
  ) {
    final weight = event.value.clamp(30.0, 300.0);
    final goal = _clampGoal(
      state.goalWeightKg,
      weight: weight,
      height: state.heightCm,
    );
    emit(state.copyWith(weightKg: weight, goalWeightKg: goal));
  }

  void _onGoalWeight(
    StartingPointGoalWeightChanged event,
    Emitter<StartingPointState> emit,
  ) {
    emit(
      state.copyWith(
        goalWeightKg: _clampGoal(
          event.value,
          weight: state.weightKg,
          height: state.heightCm,
        ),
      ),
    );
  }

  void _onHeight(
    StartingPointHeightChanged event,
    Emitter<StartingPointState> emit,
  ) {
    final height = event.value.clamp(100, 250);
    final goal = _clampGoal(
      state.goalWeightKg,
      weight: state.weightKg,
      height: height,
    );
    emit(state.copyWith(heightCm: height, goalWeightKg: goal));
  }

  void _onAge(StartingPointAgeChanged event, Emitter<StartingPointState> emit) {
    emit(state.copyWith(age: event.value.clamp(13, 100)));
  }
}
