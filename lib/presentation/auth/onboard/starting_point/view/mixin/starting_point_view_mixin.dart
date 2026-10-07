part of '../starting_point_view.dart';

mixin StartingPointViewMixin on State<StartingPointView> {
  void onBack() {
    context.pop();
  }

  void onWeightDelta(double delta) {
    final current = context.read<StartingPointBloc>().state.weightKg;
    context.read<StartingPointBloc>().add(
      StartingPointWeightChanged(current + delta),
    );
  }

  void onGoalWeightDelta(double delta) {
    final current = context.read<StartingPointBloc>().state.goalWeightKg;
    context.read<StartingPointBloc>().add(
      StartingPointGoalWeightChanged(current + delta),
    );
  }

  void onHeightDelta(int delta) {
    final current = context.read<StartingPointBloc>().state.heightCm;
    context.read<StartingPointBloc>().add(
      StartingPointHeightChanged(current + delta),
    );
  }

  void onAgeDelta(int delta) {
    final current = context.read<StartingPointBloc>().state.age;
    context.read<StartingPointBloc>().add(
      StartingPointAgeChanged(current + delta),
    );
  }

  void onContinue() {
    final state = context.read<StartingPointBloc>().state;
    getIt<OnboardingDraft>()
      ..weightKg = state.weightKg
      ..goalWeightKg = state.goalWeightKg
      ..heightCm = state.heightCm
      ..age = state.age;
    context.push(
      RoutePaths.doableHighlight.path,
      extra: StartingPointNavArgs(
        weightKg: state.weightKg,
        goalWeightKg: state.goalWeightKg,
      ),
    );
  }
}
