part of '../hunger_fourth_question_view.dart';

mixin HungerFourthQuestionViewMixin on State<HungerFourthQuestionView> {
  HungerFourthAnswer? selected;

  void selectAnswer(HungerFourthAnswer answer) {
    setState(() => selected = answer);
  }

  void onResultTapped() {
    if (selected == null) return;
    final type = math.Random().nextBool()
        ? HungerResultType.physical
        : HungerResultType.emotional;
    context.pushNamed(RoutePaths.hungerResult.name, extra: type);
  }
}
