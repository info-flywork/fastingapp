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

  /// BMI 17.5'e karşılık gelen en düşük hedef (0.5 kg'a yukarı yuvarlı).
  static double minGoalKgFor(int heightCm) {
    final m = heightCm / 100;
    return (17.5 * m * m * 2).ceil() / 2;
  }

  /// Hedef BMI 17.5'in altında (mevcut kilo zaten çok düşük ve hedef kilo
  /// vermek): sunucu reddeder, devam edilemez.
  bool get isGoalSafe => goalWeightKg >= minGoalKgFor(heightCm) - 1e-9;

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
