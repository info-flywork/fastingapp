part of 'food_skips_bloc.dart';

final class FoodSkipsState extends Equatable {
  const FoodSkipsState({this.selected = const {}});

  final Set<OnboardingFoodSkip> selected;

  FoodSkipsState copyWith({Set<OnboardingFoodSkip>? selected}) {
    return FoodSkipsState(selected: selected ?? this.selected);
  }

  @override
  List<Object?> get props => [selected];
}
