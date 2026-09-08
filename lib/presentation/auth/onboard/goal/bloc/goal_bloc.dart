import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'goal_event.dart';
part 'goal_state.dart';

enum OnboardingGoal {
  loseWeight,
  buildHabit,
  moreEnergy,
  gutReset,
}

final class GoalBloc extends Bloc<GoalEvent, GoalState> {
  GoalBloc() : super(const GoalState()) {
    on<GoalSelected>(_onSelected);
  }

  void _onSelected(GoalSelected event, Emitter<GoalState> emit) {
    emit(state.copyWith(selected: event.goal));
  }
}
