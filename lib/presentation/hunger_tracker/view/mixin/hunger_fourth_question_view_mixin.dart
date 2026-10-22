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
     await  context.pushNamed(
        RoutePaths.hungerResult.name,
        extra: HungerSessionArgs(
          flow: flow,
          resultType: evaluation.resultTypeEnum,
          recommendations: [
            for (final r in evaluation.recommendations)
              if (r.title.isNotEmpty) r.title,
          ],
          safetyFlag: evaluation.safetyFlag,
        ),
      );
    } on Object catch (e) {
      // Önceden uydurma "fiziksel" sonuç gösteriliyordu; artık hata + tekrar.
      if (!mounted) return;
      AppSnackbar.showError(context, e);
    } finally {
      if (mounted) setState(() => evaluating = false);
    }
  }
}
