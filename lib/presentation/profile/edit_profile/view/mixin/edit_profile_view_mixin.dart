part of '../edit_profile_view.dart';

/// Profili Düzenle: veri [ProfileBloc]'tan (splash / ana sayfada ısıtılır);
/// mixin yalnızca seçim ekranlarını açar ve sonucu event olarak iletir.
mixin EditProfileViewMixin on State<EditProfileView> {
  ProfileBloc get _bloc => getIt<ProfileBloc>();
  UserProfile get _profile => _bloc.state.profile;

  /// Değer yoksa (onboarding bitmemiş hesap) gösterilen yer tutucu.
  static const placeholder = '–';

  static const _defaultWeightKg = 70.0;
  static const _defaultHeightCm = 170;
  static const _defaultAge = 30;

  @override
  void initState() {
    super.initState();
    // Isıtılmadıysa (ör. ağ hatası) burada yüklenir; yüklüyse dokunmaz.
    _bloc.add(const ProfileStarted());
  }

  void onRetry() => _bloc.add(const ProfileStarted());

  void onSaveError(ProfileSaveError error) {
    AppSnackbar.show(
      context: context,
      text: error.message ?? 'common.failed'.tr(),
      type: SnackBarType.failure,
    );
  }

  void onBack() => context.pop();

  /// Hesabı sil: onay → (Apple ise token iptali) → silme talebi → çıkış.
  /// Hesap 7 gün içinde tekrar girişle geri alınabilir.
  Future<void> onDeleteAccount() async {
    final confirmed = await AppDialogs.instance.showDeleteAccount(context);
    if (confirmed != true || !mounted) return;

    try {
      final result = await getIt<AuthBloc>().deleteAccount().withLoading(
        context,
      );
      if (!mounted) return;
      if (result.hasActiveSubscription) {
        AppSnackbar.show(
          context: context,
          text: 'profile.delete_account_subscription_note'.tr(),
          type: SnackBarType.warning,
        );
      }
      context.go(RoutePaths.login.path);
    } on AuthCancelledException {
      return;
    } on Exception catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context: context,
        text: errorMessageOf(e),
        type: SnackBarType.failure,
      );
    }
  }

  Future<void> onChangePhoto() async {
    final source = await AppBottomSheets.instance.showPhotoSource(context);
    if (source == null || !mounted) return;

    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    _bloc.add(ProfilePhotoPicked(file.path));
  }

  Future<void> onEditName() async {
    final current = _bloc.state.name ?? '';
    final result = await AppBottomSheets.instance.showEditName(
      context,
      initialName: current,
    );
    final name = result?.trim();
    if (name == null || name.isEmpty || name == current) return;
    _bloc.add(ProfileNameChanged(name));
  }

  Future<void> onEditFastingTarget() async {
    final result = await context.pushNamed<OnboardingGoal>(
      RoutePaths.editFastingTarget.name,
      extra: _profile.goal,
    );
    if (result == null || result == _profile.goal) return;
    _save({'goal': result.name}, _profile.copyWith(goal: result));
  }

  Future<void> onEditWeight() async {
    final result = await AppDialogs.instance.showEditWeight(
      context,
      initialWeightKg: _profile.currentWeightKg ?? _defaultWeightKg,
    );
    if (result == null) return;
    final kg = (result.weightKg * 10).round() / 10;
    // Aynı kilo da bir tartı kaydıdır (bugün tartıldı): sunucuya gider.
    // Sunucu yeni bir kilo kaydı açar (profilde tek değer tutulmaz).
    _save({'weightKg': kg}, _profile.copyWith(currentWeightKg: kg));
  }

  String formatWeight(double? kg) {
    if (kg == null) return placeholder;
    final rounded = (kg * 10).round() / 10;
    if (rounded == rounded.roundToDouble()) {
      return rounded.toStringAsFixed(0);
    }
    return rounded.toStringAsFixed(1);
  }

  Future<void> onEditHeight() async {
    final result = await context.pushNamed<HeightEditResult>(
      RoutePaths.editHeight.name,
      extra: HeightEditResult(
        heightCm: _profile.heightCm ?? _defaultHeightCm,
        age: _profile.age ?? _defaultAge,
      ),
    );
    if (result == null) return;
    if (result.heightCm == _profile.heightCm && result.age == _profile.age) {
      return;
    }
    _save({
      'heightCm': result.heightCm,
      'age': result.age,
    }, _profile.copyWith(heightCm: result.heightCm, age: result.age));
  }

  Future<void> onEditGender() async {
    final result = await context.pushNamed<OnboardingGender>(
      RoutePaths.editGender.name,
      extra: _profile.gender,
    );
    if (result == null || result == _profile.gender) return;
    _save({'gender': result.name}, _profile.copyWith(gender: result));
  }

  Future<void> onEditDietType() async {
    final result = await context.pushNamed<OnboardingDiet>(
      RoutePaths.editDietType.name,
      extra: _profile.diet,
    );
    if (result == null || result == _profile.diet) return;
    _save({'diet': result.name}, _profile.copyWith(diet: result));
  }

  Future<void> onEditPreferredFoods() async {
    final result = await context.pushNamed<Set<OnboardingFoodLove>>(
      RoutePaths.editPreferredFoods.name,
      extra: _profile.foodLoves.toList(),
    );
    // Sunucu en az bir tercih ister.
    if (result == null || result.isEmpty) return;
    if (setEquals(result, _profile.foodLoves)) return;
    _save({
      'foodLoves': result.map((e) => e.name).toList(),
    }, _profile.copyWith(foodLoves: result));
  }

  Future<void> onEditSkippedFoods() async {
    final result = await context.pushNamed<Set<OnboardingFoodSkip>>(
      RoutePaths.editSkippedFoods.name,
      extra: _profile.foodSkips.toList(),
    );
    if (result == null || setEquals(result, _profile.foodSkips)) return;
    _save({
      'foodSkips': result.map((e) => e.name).toList(),
    }, _profile.copyWith(foodSkips: result));
  }

  /// Bir sonraki oruçtan geçerli; premium plan için paywall bloc'ta.
  Future<void> onEditFastingPlan() async {
    final current = _bloc.state.plan;
    final result = await context.pushNamed<OnboardingFastingPlan>(
      RoutePaths.editFastingPlan.name,
      extra: current,
    );
    if (result == null || result == current || !mounted) return;
    final needsAck = planRequiresSafetyAck(OnboardingDraft.planCodes[result]);
    if (needsAck) {
      final ok = await AppDialogs.instance.showPlanSafetyAck(context);
      if (ok != true) return;
    }
    _bloc.add(ProfilePlanChanged(result, safetyAcknowledged: needsAck));
  }

  void _save(Map<String, dynamic> fields, UserProfile optimistic) =>
      _bloc.add(ProfileFieldsChanged(fields: fields, optimistic: optimistic));
}
