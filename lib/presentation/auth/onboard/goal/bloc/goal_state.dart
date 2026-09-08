part of 'goal_bloc.dart';

final class GoalState extends Equatable {
  const GoalState({this.selected});

  final OnboardingGoal? selected;

  GoalState copyWith({OnboardingGoal? selected}) {
    return GoalState(selected: selected ?? this.selected);
  }

  @override
  List<Object?> get props => [selected];
}
