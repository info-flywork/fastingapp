part of 'fasting_reason_bloc.dart';

final class FastingReasonState extends Equatable {
  const FastingReasonState({
    this.selected,
    this.targetDate,
  });

  final OnboardingFastingReason? selected;
  final DateTime? targetDate;

  FastingReasonState copyWith({
    OnboardingFastingReason? selected,
    DateTime? targetDate,
  }) {
    return FastingReasonState(
      selected: selected ?? this.selected,
      targetDate: targetDate ?? this.targetDate,
    );
  }

  @override
  List<Object?> get props => [selected, targetDate];
}
