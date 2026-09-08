part of 'goal_bloc.dart';

sealed class GoalEvent extends Equatable {
  const GoalEvent();

  @override
  List<Object?> get props => [];
}

final class GoalSelected extends GoalEvent {
  const GoalSelected(this.goal);

  final OnboardingGoal goal;

  @override
  List<Object?> get props => [goal];
}
