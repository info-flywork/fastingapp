part of '../hunger_result_view.dart';

mixin HungerResultViewMixin on State<HungerResultView> {
  void onPrimaryTapped() {
    context.pushNamed(
      RoutePaths.hungerLog.name,
      extra: widget.type,
    );
  }

  void onSecondaryTapped() {
    context.pushNamed(RoutePaths.chat.name);
  }
}
