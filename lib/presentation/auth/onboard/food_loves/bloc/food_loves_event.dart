part of 'food_loves_bloc.dart';

sealed class FoodLovesEvent extends Equatable {
  const FoodLovesEvent();

  @override
  List<Object?> get props => [];
}

final class FoodLoveToggled extends FoodLovesEvent {
  const FoodLoveToggled(this.food);

  final OnboardingFoodLove food;

  @override
  List<Object?> get props => [food];
}
