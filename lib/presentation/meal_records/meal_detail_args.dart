/// Öğün detay rotası (`RoutePaths.mealDetail`).
final class MealDetailArgs {
  const MealDetailArgs({this.mealId, this.initialEatenAt});

  /// Düzenleme; yoksa yeni kayıt.
  final String? mealId;

  /// Yeni kayıt için başlangıç zamanı (ör. seçili gün).
  final DateTime? initialEatenAt;
}
