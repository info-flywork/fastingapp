part of '../hunger_fourth_question_view.dart';

mixin HungerFourthQuestionViewMixin on State<HungerFourthQuestionView> {
  HungerFourthAnswer? selected;
  bool evaluating = false;

  HungerRepository get _hunger => getIt<HungerRepository>();

  void selectAnswer(HungerFourthAnswer answer) {
    setState(() => selected = answer);
  }

  Future<void> onResultTapped() async {
    if (selected == null || evaluating) return;
    setState(() => evaluating = true);
    final flow = widget.args.copyWith(q4: selected!.name);
    try {
      final evaluation = await _hunger.evaluate(flow);
      if (!mounted) return;
      context.pushNamed(
        RoutePaths.hungerResult.name,
        extra: HungerSessionArgs(
          flow: flow,
          resultType: evaluation.resultTypeEnum,
        ),
      );
    } on Object {
      if (!mounted) return;
      context.pushNamed(
        RoutePaths.hungerResult.name,
        extra: HungerSessionArgs(
          flow: flow,
          resultType: HungerResultType.physical,
        ),
      );
    } finally {
      if (mounted) setState(() => evaluating = false);
    }
  }
}
