part of '../hunger_log_view.dart';

mixin HungerLogViewMixin on State<HungerLogView> {
  late final TextEditingController notesController;
  late final DateTime loggedAt;

  @override
  void initState() {
    super.initState();
    notesController = TextEditingController();
    loggedAt = DateTime.now();
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  String get formattedTime {
    final locale = context.locale.toString();
    final today = 'hunger_log_page.today'.tr();
    final time = DateFormat.jm(locale).format(loggedAt);
    return '$today, $time';
  }

  void onSaveTapped() {
    context.pushNamed(RoutePaths.hungerSuccess.name);
  }

  void onSkipTapped() {
    context.pop();
  }
}
