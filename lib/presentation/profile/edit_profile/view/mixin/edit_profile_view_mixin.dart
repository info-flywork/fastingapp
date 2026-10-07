part of '../edit_profile_view.dart';

mixin EditProfileViewMixin on State<EditProfileView> {
  String? photoPath;
  String displayName = 'Alex E.';
  OnboardingGoal fastingTarget = OnboardingGoal.loseWeight;
  OnboardingFastingPlan fastingPlan = OnboardingFastingPlan.sixteenEight;
  OnboardingGender gender = OnboardingGender.man;
  OnboardingDiet dietType = OnboardingDiet.vegetarian;
  Set<OnboardingFoodLove> preferredFoods = {
    OnboardingFoodLove.chicken,
    OnboardingFoodLove.fish,
    OnboardingFoodLove.rice,
    OnboardingFoodLove.pasta,
  };
  Set<OnboardingFoodSkip> skippedFoods = {
    OnboardingFoodSkip.mushrooms,
    OnboardingFoodSkip.olives,
    OnboardingFoodSkip.onions,
  };
  double weightKg = 74;
  int heightCm = 173;
  int age = 29;

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
      context.go(RoutePaths.welcome.path);
    } on AuthCancelledException {
      return;
    } on Exception catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context: context,
        text: e.toString(),
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

    setState(() => photoPath = file.path);
  }

  Future<void> onEditName() async {
    final result = await AppBottomSheets.instance.showEditName(
      context,
      initialName: displayName,
    );
    if (result == null || !mounted) return;
    setState(() => displayName = result);
  }

  Future<void> onEditFastingTarget() async {
    final result = await context.pushNamed<OnboardingGoal>(
      RoutePaths.editFastingTarget.name,
      extra: fastingTarget,
    );
    if (result == null || !mounted) return;
    setState(() => fastingTarget = result);
  }

  Future<void> onEditWeight() async {
    final result = await AppDialogs.instance.showEditWeight(
      context,
      initialWeightKg: weightKg,
    );
    if (result == null || !mounted) return;
    setState(() => weightKg = result.weightKg);
  }

  String _formatWeight(double kg) {
    final rounded = (kg * 10).round() / 10;
    if (rounded == rounded.roundToDouble()) {
      return rounded.toStringAsFixed(0);
    }
    return rounded.toStringAsFixed(1);
  }

  Future<void> onEditHeight() async {
    final result = await context.pushNamed<HeightEditResult>(
      RoutePaths.editHeight.name,
      extra: HeightEditResult(heightCm: heightCm, age: age),
    );
    if (result == null || !mounted) return;
    setState(() {
      heightCm = result.heightCm;
      age = result.age;
    });
  }

  Future<void> onEditGender() async {
    final result = await context.pushNamed<OnboardingGender>(
      RoutePaths.editGender.name,
      extra: gender,
    );
    if (result == null || !mounted) return;
    setState(() => gender = result);
  }

  Future<void> onEditDietType() async {
    final result = await context.pushNamed<OnboardingDiet>(
      RoutePaths.editDietType.name,
      extra: dietType,
    );
    if (result == null || !mounted) return;
    setState(() => dietType = result);
  }

  Future<void> onEditPreferredFoods() async {
    final result = await context.pushNamed<Set<OnboardingFoodLove>>(
      RoutePaths.editPreferredFoods.name,
      extra: preferredFoods.toList(),
    );
    if (result == null || !mounted) return;
    setState(() => preferredFoods = result);
  }

  Future<void> onEditSkippedFoods() async {
    final result = await context.pushNamed<Set<OnboardingFoodSkip>>(
      RoutePaths.editSkippedFoods.name,
      extra: skippedFoods.toList(),
    );
    if (result == null || !mounted) return;
    setState(() => skippedFoods = result);
  }

  Future<void> onEditFastingPlan() async {
    final result = await context.pushNamed<OnboardingFastingPlan>(
      RoutePaths.editFastingPlan.name,
      extra: fastingPlan,
    );
    if (result == null || !mounted) return;
    setState(() => fastingPlan = result);
  }
}
