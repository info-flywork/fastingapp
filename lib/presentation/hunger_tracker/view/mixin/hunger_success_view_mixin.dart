part of '../hunger_success_view.dart';

mixin HungerSuccessViewMixin on State<HungerSuccessView> {
  /// Geçmiş + haftalık şerit (fiziksel / duygusal dağılımı). Önceden boştu.
  void onInsightsTapped() {
    // Kaydedilmiş akış ekranları yığında kalmasın: ana sayfa → geçmiş.
    GoRouter.of(context)
      ..go(RoutePaths.home.path)
      ..pushNamed(RoutePaths.hungerHistoryLog.name);
  }

  void onBackToHomeTapped() {
    context.go(RoutePaths.home.path);
  }
}
