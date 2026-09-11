import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'obstacles_event.dart';
part 'obstacles_state.dart';

enum OnboardingObstacle {
  tooRestrictive,
  lostMotivation,
  noTimeToCook,
  tooConfusing,
  lifeGotBusy,
  hitPlateau,
}

final class ObstaclesBloc extends Bloc<ObstaclesEvent, ObstaclesState> {
  ObstaclesBloc() : super(const ObstaclesState()) {
    on<ObstacleSelected>(_onSelected);
  }

  void _onSelected(ObstacleSelected event, Emitter<ObstaclesState> emit) {
    emit(state.copyWith(selected: event.obstacle));
  }
}
