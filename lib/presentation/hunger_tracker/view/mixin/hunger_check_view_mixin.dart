part of '../hunger_check_view.dart';

mixin HungerCheckViewMixin on State<HungerCheckView> {
  HungerFlowArgs get flowArgs => widget.args;

  void onQuickCheckTapped() {
    context.pushNamed(
      RoutePaths.hungerFirstQuestion.name,
      extra: flowArgs,
    );
  }

  void onFullCheckTapped() {
    // Full check detay kaydı — sonraki adım.
  }
}
