part of '../hunger_log_view.dart';

mixin HungerLogViewMixin on State<HungerLogView> {
  late final TextEditingController notesController;
  late final DateTime loggedAt;
  bool saving = false;

  HungerRepository get _hunger => getIt<HungerRepository>();

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

  Future<void> onSaveTapped() async {
    if (saving) return;
    final session = widget.session;
    // Cevaplanmış soru akışı yoksa kaydedilecek bir şey yok.
    if (session == null) {
      context.pop();
      return;
    }
    setState(() => saving = true);
    try {
      await _hunger.saveCheckin(
        flow: session.flow,
        mode: session.flow.mode,
        notes: notesController.text.trim(),
      );
      DataSync.afterWrite();
      if (!mounted) return;
      await context.pushNamed(RoutePaths.hungerSuccess.name);
    } on Object catch (e) {
      // Kaydedilmediyse başarı ekranı gösterilmez.
      if (!mounted) return;
      AppSnackbar.showError(context, e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void onSkipTapped() {
    context.pop();
  }
}
