part of 'obstacles_bloc.dart';

final class ObstaclesState extends Equatable {
  const ObstaclesState({this.selected = const {}});

  final Set<OnboardingObstacle> selected;

  bool get hasSelection => selected.isNotEmpty;

  ObstaclesState copyWith({Set<OnboardingObstacle>? selected}) {
    return ObstaclesState(selected: selected ?? this.selected);
  }

  @override
  List<Object?> get props => [selected];
}
