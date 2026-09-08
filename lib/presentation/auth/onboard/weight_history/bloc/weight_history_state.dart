part of 'weight_history_bloc.dart';

final class WeightHistoryState extends Equatable {
  const WeightHistoryState({this.selected});

  final OnboardingWeightHistory? selected;

  WeightHistoryState copyWith({OnboardingWeightHistory? selected}) {
    return WeightHistoryState(selected: selected ?? this.selected);
  }

  @override
  List<Object?> get props => [selected];
}
