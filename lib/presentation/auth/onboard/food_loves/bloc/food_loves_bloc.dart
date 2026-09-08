import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'food_loves_event.dart';
part 'food_loves_state.dart';

enum OnboardingFoodLove {
  chicken,
  fish,
  rice,
  redMeat,
  pasta,
  salads,
  cheese,
  eggs,
  spicy,
  noodles,
  fruit,
  avocado,
  sweets,
}

final class FoodLovesBloc extends Bloc<FoodLovesEvent, FoodLovesState> {
  FoodLovesBloc() : super(const FoodLovesState()) {
    on<FoodLoveToggled>(_onToggled);
  }

  void _onToggled(FoodLoveToggled event, Emitter<FoodLovesState> emit) {
    final next = Set<OnboardingFoodLove>.from(state.selected);
    if (next.contains(event.food)) {
      next.remove(event.food);
    } else {
      next.add(event.food);
    }
    emit(state.copyWith(selected: next));
  }
}
