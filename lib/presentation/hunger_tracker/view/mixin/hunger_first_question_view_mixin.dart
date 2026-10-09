part of '../hunger_first_question_view.dart';

mixin HungerFirstQuestionViewMixin on State<HungerFirstQuestionView> {
  HungerFirstAnswer? selected;

  HungerFlowArgs get flowArgs => widget.args;

  void selectAnswer(HungerFirstAnswer answer) {
    setState(() => selected = answer);
  }

  void onNextTapped() {
    if (selected == null) return;
    context.pushNamed(
      RoutePaths.hungerSecondQuestion.name,
      extra: flowArgs.copyWith(q1: selected!.name),
    );
  }
}
