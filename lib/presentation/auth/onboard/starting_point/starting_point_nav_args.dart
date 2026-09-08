/// Starting point → doable highlight arası aktarılan kilo verisi.
final class StartingPointNavArgs {
  const StartingPointNavArgs({
    required this.weightKg,
    required this.goalWeightKg,
  });

  final double weightKg;
  final double goalWeightKg;

  double get deltaKg => (weightKg - goalWeightKg).abs();
}
