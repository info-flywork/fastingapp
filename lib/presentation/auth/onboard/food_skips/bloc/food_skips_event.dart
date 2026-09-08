part of 'food_skips_bloc.dart';

sealed class FoodSkipsEvent extends Equatable {
  const FoodSkipsEvent();

  @override
  List<Object?> get props => [];
}

final class FoodSkipToggled extends FoodSkipsEvent {
  const FoodSkipToggled(this.food);

  final OnboardingFoodSkip food;

  @override
  List<Object?> get props => [food];
}
