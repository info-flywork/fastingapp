import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'food_skips_event.dart';
part 'food_skips_state.dart';

enum OnboardingFoodSkip {
  mushrooms,
  olives,
  seafood,
  onions,
  broccoli,
  tooSpicy,
  dairy,
  nuts,
  beans,
  eggplant,
}

final class FoodSkipsBloc extends Bloc<FoodSkipsEvent, FoodSkipsState> {
  FoodSkipsBloc() : super(const FoodSkipsState()) {
    on<FoodSkipToggled>(_onToggled);
  }

  void _onToggled(FoodSkipToggled event, Emitter<FoodSkipsState> emit) {
    final next = Set<OnboardingFoodSkip>.from(state.selected);
    if (next.contains(event.food)) {
      next.remove(event.food);
    } else {
      next.add(event.food);
    }
    emit(state.copyWith(selected: next));
  }
}
