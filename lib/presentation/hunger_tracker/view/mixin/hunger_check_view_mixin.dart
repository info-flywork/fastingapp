part of '../hunger_check_view.dart';

mixin HungerCheckViewMixin on State<HungerCheckView> {
  HungerFlowArgs get flowArgs => widget.args;

  void onQuickCheckTapped() {
    context.pushNamed(RoutePaths.hungerFirstQuestion.name, extra: flowArgs);
  }

  /// Aynı sorular, sonunda ayrıntılı kayıt (`mode: full`). Önceden geçmiş
  /// listesini açıyordu.
  void onFullCheckTapped() {
    context.pushNamed(
      RoutePaths.hungerFirstQuestion.name,
      extra: flowArgs.copyWith(mode: 'full'),
    );
  }
}
