part of 'starting_point_bloc.dart';

final class StartingPointState extends Equatable {
  const StartingPointState({
    this.weightKg = 70,
    this.goalWeightKg = 65,
    this.heightCm = 170,
    this.age = 25,
  });

  final double weightKg;
  final double goalWeightKg;
  final int heightCm;
  final int age;

  StartingPointState copyWith({
    double? weightKg,
    double? goalWeightKg,
    int? heightCm,
    int? age,
  }) {
    return StartingPointState(
      weightKg: weightKg ?? this.weightKg,
      goalWeightKg: goalWeightKg ?? this.goalWeightKg,
      heightCm: heightCm ?? this.heightCm,
      age: age ?? this.age,
    );
  }

  @override
  List<Object?> get props => [weightKg, goalWeightKg, heightCm, age];
}
