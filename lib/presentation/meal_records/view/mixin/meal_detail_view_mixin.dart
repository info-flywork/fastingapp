part of '../meal_detail_view.dart';

mixin MealDetailViewMixin on State<MealDetailView> {
  late DateTime mealAt;

  /// Sunucudaki saat: düzenlemede yalnızca değiştiyse gönderilir (30 günden
  /// eski öğünün notu da düzenlenebilsin; sunucu eski `eatenAt`'i reddeder).
  DateTime? _loadedMealAt;
  MealKind? mealKind;
  MealDietChoice? dietChoice;
  late MealFeeling feeling;
  late final TextEditingController notesController;
  bool loading = false;
  bool saving = false;
  bool deleting = false;
  String? loadError;

  MealsRepository get _meals => getIt<MealsRepository>();

  bool get isEditing => widget.mealId != null && widget.mealId!.isNotEmpty;

  void initMealDetail() {
    mealAt = widget.initialEatenAt ?? DateTime.now();
    mealKind = null;
    dietChoice = null;
    feeling = MealFeeling.superFeeling;
    notesController = TextEditingController();
    if (isEditing) unawaited(_loadMeal());
  }

  /// Listede görülen öğün beklemeden gösterilir; sunucu yanıtı yalnızca
  /// kullanıcı henüz bir şey değiştirmediyse uygulanır (yazdığı silinmesin).
  Future<void> _loadMeal() async {
    final cached = _meals.cachedMeal(widget.mealId!);
    if (cached != null) _applyMeal(cached);
    setState(() {
      loading = cached == null;
      loadError = null;
    });
    try {
      final meal = await _meals.getById(widget.mealId!);
      if (!mounted || meal == null) return;
      if (cached == null || !_editedSince(cached)) {
        setState(() => _applyMeal(meal));
      }
    } on NetworkException catch (e) {
      // Önbellekten gösterilen öğün varsa hata ekranı açılmaz.
      if (mounted && cached == null) setState(() => loadError = e.message);
    } on Object {
      if (mounted && cached == null) {
        setState(() => loadError = 'meal_records_page.empty_title'.tr());
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _applyMeal(MealRecord meal) {
    mealAt = meal.eatenAt;
    _loadedMealAt = meal.eatenAt;
    mealKind = _kindFromApi(meal.kind);
    dietChoice = _dietFromApi(meal.dietType);
    feeling = _feelingFromApi(meal.feeling) ?? MealFeeling.superFeeling;
    notesController.text = meal.notes ?? '';
  }

  /// Önbellekten açıldıktan sonra kullanıcı bir alanı değiştirdi mi.
  bool _editedSince(MealRecord shown) =>
      mealAt != shown.eatenAt ||
      mealKind != _kindFromApi(shown.kind) ||
      dietChoice != _dietFromApi(shown.dietType) ||
      feeling != (_feelingFromApi(shown.feeling) ?? MealFeeling.superFeeling) ||
      notesController.text != (shown.notes ?? '');

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  String mealTimeLabel(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(mealAt);
    final time = DateFormat.jm(context.locale.toString()).format(mealAt);
    if (DateUtils.isSameDay(day, today)) {
      return '${'meal_records_page.today'.tr()}, $time';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (DateUtils.isSameDay(day, yesterday)) {
      return '${'meal_records_page.yesterday'.tr()}, $time';
    }
    return '${DateFormat.MMMd(context.locale.toString()).format(mealAt)}, '
        '$time';
  }

  Future<void> onMealTimeEditTapped() async {
    final result = await AppDialogs.instance.showMealDatePicker(
      context,
      initialDate: mealAt,
      includeTime: true,
      maxDaysBack: 30,
    );
    if (result == null || !mounted) return;
    setState(() => mealAt = result.date);
  }

  void onMealKindSelected(MealKind kind) {
    setState(() => mealKind = kind);
  }

  void onDietSelected(MealDietChoice diet) {
    setState(() => dietChoice = diet);
  }

  void onFeelingSelected(MealFeeling value) {
    setState(() => feeling = value);
  }

  Future<void> onDeleteTapped() async {
    if (!isEditing || saving || deleting) return;
    final confirmed = await AppDialogs.instance.showDeleteMeal(context);
    if (confirmed != true || !mounted) return;
    setState(() => deleting = true);
    try {
      await _meals.deleteMeal(widget.mealId!);
      DataSync.afterWrite();
      if (!mounted) return;
      context.pop();
    } on NetworkException catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context: context,
          text: e.message,
          type: SnackBarType.failure,
        );
      }
    } on Object {
      if (mounted) {
        AppSnackbar.show(
          context: context,
          text: 'meal_detail.delete_failed'.tr(),
          type: SnackBarType.failure,
        );
      }
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  Future<void> onSaveTapped() async {
    if (saving || deleting) return;
    setState(() => saving = true);
    var endFast = false;
    try {
      final notes = notesController.text.trim();
      if (isEditing) {
        await _meals.updateMeal(
          widget.mealId!,
          eatenAt: mealAt == _loadedMealAt ? null : mealAt,
          kind: mealKind?.apiValue,
          dietType: dietChoice?.apiValue,
          feeling: feeling.apiValue,
          notes: notes.isEmpty ? null : notes,
          clearNotes: notes.isEmpty,
        );
      } else {
        final result = await _meals.createManual(
          eatenAt: mealAt,
          kind: mealKind?.apiValue,
          dietType: dietChoice?.apiValue,
          feeling: feeling.apiValue,
          notes: notes.isEmpty ? null : notes,
        );
        if (result.suggestEndFast && mounted) {
          final choice = await AppDialogs.instance.showEndFast(context);
          // Oruç sürsün: öğün yazılmasın.
          if (choice == false) {
            final id = result.meal?.id;
            if (id != null && id.isNotEmpty) await _meals.deleteMeal(id);
            return;
          }
          endFast = choice ?? false;
        }
      }
      DataSync.afterWrite();
      if (!mounted) return;
      context.pop();
      // Öğün oruç sırasında kaydedildi ve kullanıcı bitirmek istedi.
      if (endFast) await FastingFinishFlow.open();
    } on NetworkException catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context: context,
          text: e.message,
          type: SnackBarType.failure,
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  static MealKind? _kindFromApi(String? v) => switch (v) {
    'meal' => MealKind.meal,
    'snack' => MealKind.snack,
    _ => null,
  };

  static MealDietChoice? _dietFromApi(String? v) => switch (v) {
    'ketogenic' => MealDietChoice.ketogenic,
    'lowCarb' => MealDietChoice.lowCarb,
    'mixed' => MealDietChoice.mixed,
    'highCarb' => MealDietChoice.highCarb,
    'notSure' => MealDietChoice.notSure,
    _ => null,
  };

  static MealFeeling? _feelingFromApi(String? v) => switch (v) {
    'meh' => MealFeeling.meh,
    'good' => MealFeeling.good,
    'super' => MealFeeling.superFeeling,
    _ => null,
  };
}

extension on MealKind {
  String get apiValue => switch (this) {
    MealKind.meal => 'meal',
    MealKind.snack => 'snack',
  };
}

extension on MealDietChoice {
  String get apiValue => switch (this) {
    MealDietChoice.ketogenic => 'ketogenic',
    MealDietChoice.lowCarb => 'lowCarb',
    MealDietChoice.mixed => 'mixed',
    MealDietChoice.highCarb => 'highCarb',
    MealDietChoice.notSure => 'notSure',
  };
}

extension on MealFeeling {
  String get apiValue => switch (this) {
    MealFeeling.meh => 'meh',
    MealFeeling.good => 'good',
    MealFeeling.superFeeling => 'super',
  };
}
