import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'diet_event.dart';
part 'diet_state.dart';

enum OnboardingDiet {
  everything,
  vegetarian,
  pescatarian,
  vegan,
  lowCarb,
  mediterranean,
}

final class DietBloc extends Bloc<DietEvent, DietState> {
  DietBloc() : super(const DietState()) {
    on<DietSelected>(_onSelected);
  }

  void _onSelected(DietSelected event, Emitter<DietState> emit) {
    emit(state.copyWith(selected: event.diet));
  }
}
