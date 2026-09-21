part of '../hunger_third_question_view.dart';

mixin HungerThirdQuestionViewMixin on State<HungerThirdQuestionView> {
  late final Set<HungerBodyNotice> selected;

  @override
  void initState() {
    super.initState();
    selected = {...widget.args.toBodyNotices()};
  }

  void toggleNotice(HungerBodyNotice notice) {
    setState(() {
      if (selected.contains(notice)) {
        selected.remove(notice);
      } else {
        selected.add(notice);
      }
    });
  }

  void onNextTapped() {
    if (selected.isEmpty) return;
    context.pushNamed(
      RoutePaths.hungerFourthQuestion.name,
      extra: widget.args,
    );
  }
}
