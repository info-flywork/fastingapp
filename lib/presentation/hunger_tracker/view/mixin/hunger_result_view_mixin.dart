part of '../hunger_result_view.dart';

mixin HungerResultViewMixin on State<HungerResultView> {
  void onPrimaryTapped() {
    context.pushNamed(
      RoutePaths.hungerLog.name,
      extra:
          widget.session ??
          HungerSessionArgs(
            flow: const HungerFlowArgs(),
            resultType: widget.type,
          ),
    );
  }

  bool get _isFasting => getIt<FastingSessionCubit>().state.isFasting;

  /// Güvenlik bayrağında oruç sürüyorsa doğrudan bitirme akışı.
  Future<void> onEndFastTapped() async {
    await FastingFinishFlow.open();
  }

  void onSecondaryTapped() {
    context.pushNamed(RoutePaths.chat.name);
  }
}
