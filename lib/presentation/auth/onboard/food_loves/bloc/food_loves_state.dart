part of 'food_loves_bloc.dart';

final class FoodLovesState extends Equatable {
  const FoodLovesState({this.selected = const {}});

  final Set<OnboardingFoodLove> selected;

  bool get hasSelection => selected.isNotEmpty;

  FoodLovesState copyWith({Set<OnboardingFoodLove>? selected}) {
    return FoodLovesState(selected: selected ?? this.selected);
  }

  @override
  List<Object?> get props => [selected];
}
