import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'fasting_plan_event.dart';
part 'fasting_plan_state.dart';

enum OnboardingFastingPlan {
  sixteenEight,
  fourteenTen,
  eighteenSix,
  twentyFour,
  omad,
  fiveTwo,
}

final class FastingPlanBloc extends Bloc<FastingPlanEvent, FastingPlanState> {
  FastingPlanBloc() : super(const FastingPlanState()) {
    on<FastingPlanSelected>(_onSelected);
  }

  void _onSelected(FastingPlanSelected event, Emitter<FastingPlanState> emit) {
    emit(state.copyWith(selected: event.plan));
  }
}
