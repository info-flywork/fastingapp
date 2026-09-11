part of 'fasting_plan_bloc.dart';

final class FastingPlanState extends Equatable {
  const FastingPlanState({this.selected});

  final OnboardingFastingPlan? selected;

  FastingPlanState copyWith({OnboardingFastingPlan? selected}) {
    return FastingPlanState(selected: selected ?? this.selected);
  }

  @override
  List<Object?> get props => [selected];
}
