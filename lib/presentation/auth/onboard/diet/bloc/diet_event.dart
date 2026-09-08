part of 'diet_bloc.dart';

sealed class DietEvent extends Equatable {
  const DietEvent();

  @override
  List<Object?> get props => [];
}

final class DietSelected extends DietEvent {
  const DietSelected(this.diet);

  final OnboardingDiet diet;

  @override
  List<Object?> get props => [diet];
}
