part of 'diet_bloc.dart';

final class DietState extends Equatable {
  const DietState({this.selected});

  final OnboardingDiet? selected;

  DietState copyWith({OnboardingDiet? selected}) {
    return DietState(selected: selected ?? this.selected);
  }

  @override
  List<Object?> get props => [selected];
}
