part of 'obstacles_bloc.dart';

sealed class ObstaclesEvent extends Equatable {
  const ObstaclesEvent();

  @override
  List<Object?> get props => [];
}

final class ObstacleSelected extends ObstaclesEvent {
  const ObstacleSelected(this.obstacle);

  final OnboardingObstacle obstacle;

  @override
  List<Object?> get props => [obstacle];
}
