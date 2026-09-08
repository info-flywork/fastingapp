part of 'starting_point_bloc.dart';

sealed class StartingPointEvent extends Equatable {
  const StartingPointEvent();

  @override
  List<Object?> get props => [];
}

final class StartingPointWeightChanged extends StartingPointEvent {
  const StartingPointWeightChanged(this.value);

  final double value;

  @override
  List<Object?> get props => [value];
}

final class StartingPointGoalWeightChanged extends StartingPointEvent {
  const StartingPointGoalWeightChanged(this.value);

  final double value;

  @override
  List<Object?> get props => [value];
}

final class StartingPointHeightChanged extends StartingPointEvent {
  const StartingPointHeightChanged(this.value);

  final int value;

  @override
  List<Object?> get props => [value];
}

final class StartingPointAgeChanged extends StartingPointEvent {
  const StartingPointAgeChanged(this.value);

  final int value;

  @override
  List<Object?> get props => [value];
}
