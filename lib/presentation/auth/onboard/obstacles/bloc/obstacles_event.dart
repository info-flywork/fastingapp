part of 'obstacles_bloc.dart';

sealed class ObstaclesEvent extends Equatable {
  const ObstaclesEvent();

  @override
  List<Object?> get props => [];
}

final class ObstacleToggled extends ObstaclesEvent {
  const ObstacleToggled(this.obstacle);

  final OnboardingObstacle obstacle;

  @override
  List<Object?> get props => [obstacle];
}
