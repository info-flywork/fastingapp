part of 'weight_history_bloc.dart';

sealed class WeightHistoryEvent extends Equatable {
  const WeightHistoryEvent();

  @override
  List<Object?> get props => [];
}

final class WeightHistorySelected extends WeightHistoryEvent {
  const WeightHistorySelected(this.history);

  final OnboardingWeightHistory history;

  @override
  List<Object?> get props => [history];
}
