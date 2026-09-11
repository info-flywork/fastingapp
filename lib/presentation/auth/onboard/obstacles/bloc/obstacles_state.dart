part of 'obstacles_bloc.dart';

final class ObstaclesState extends Equatable {
  const ObstaclesState({this.selected});

  final OnboardingObstacle? selected;

  ObstaclesState copyWith({OnboardingObstacle? selected}) {
    return ObstaclesState(selected: selected ?? this.selected);
  }

  @override
  List<Object?> get props => [selected];
}
