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
    on<ObstacleToggled>(_onToggled);
  }

  void _onToggled(ObstacleToggled event, Emitter<ObstaclesState> emit) {
    final next = Set<OnboardingObstacle>.from(state.selected);
    if (next.contains(event.obstacle)) {
      next.remove(event.obstacle);
    } else {
      next.add(event.obstacle);
    }
    emit(state.copyWith(selected: next));
  }
}
