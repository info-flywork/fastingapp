part of 'fasting_plan_bloc.dart';

sealed class FastingPlanEvent extends Equatable {
  const FastingPlanEvent();

  @override
  List<Object?> get props => [];
}

final class FastingPlanSelected extends FastingPlanEvent {
  const FastingPlanSelected(this.plan);

  final OnboardingFastingPlan plan;

  @override
  List<Object?> get props => [plan];
}
