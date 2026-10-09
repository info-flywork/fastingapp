part of '../hunger_second_question_view.dart';

mixin HungerSecondQuestionViewMixin on State<HungerSecondQuestionView> {
  HungerSecondAnswer? selected;

  HungerFlowArgs get flowArgs => widget.args;

  void selectAnswer(HungerSecondAnswer answer) {
    setState(() => selected = answer);
  }

  void onNextTapped() {
    if (selected == null) return;
    context.pushNamed(
      RoutePaths.hungerThirdQuestion.name,
      extra: flowArgs.copyWith(q2: selected!.name),
    );
  }
}
