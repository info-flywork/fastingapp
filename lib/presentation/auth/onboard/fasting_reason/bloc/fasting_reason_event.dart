part of 'fasting_reason_bloc.dart';

sealed class FastingReasonEvent extends Equatable {
  const FastingReasonEvent();

  @override
  List<Object?> get props => [];
}

final class FastingReasonSelected extends FastingReasonEvent {
  const FastingReasonSelected(this.reason);

  final OnboardingFastingReason reason;

  @override
  List<Object?> get props => [reason];
}
