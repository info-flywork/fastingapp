part of '../login_view.dart';

mixin LoginViewMixin on State<LoginView> {
  bool get _afterOnboarding => widget.afterOnboarding;

  Future<void> onApple() => _login(
    () => context.read<WelcomeBloc>().loginWithApple(
      afterOnboarding: _afterOnboarding,
    ),
  );

  Future<void> onGoogle() => _login(
    () => context.read<WelcomeBloc>().loginWithGoogle(
      afterOnboarding: _afterOnboarding,
    ),
  );

  /// Onboarding sonunda misafir oturumu zaten açık: yeni giriş yok, ana
  /// sayfaya geçilir.
  Future<void> onGuest() => _login(
    () => _afterOnboarding
        ? context.read<WelcomeBloc>().continueAsGuest()
        : context.read<WelcomeBloc>().loginAsGuest(),
  );

  Future<void> _login(Future<String> Function() action) async {
    try {
      final navigateTo = await action().withLoading(context);
      if (!mounted) return;
      context.go(navigateTo);
    } on AuthCancelledException {
      return;
    } on AccountPendingDeletionException<AuthResponse> catch (e) {
      if (!mounted) return;
      await _offerRestore(e);
    } on Exception catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context: context,
        text: switch (e) {
          NetworkException(:final message) => message,
          AuthException(:final message) => message,
          _ => errorMessageOf(e),
        },
        type: SnackBarType.failure,
      );
    }
  }

  /// "Silme talebin var, geri almak ister misin?" — evet: hesap açılır ve
  /// giriş tamamlanır; hayır: yarım kalan sosyal oturum kapatılır.
  Future<void> _offerRestore(
    AccountPendingDeletionException<AuthResponse> pending,
  ) async {
    final bloc = context.read<WelcomeBloc>();
    final restore = await AppDialogs.instance.showRestoreAccount(
      context,
      scheduledFor: pending.scheduledFor,
    );
    if (!mounted) return;
    if (restore != true) {
      await bloc.discardPendingLogin();
      return;
    }
    await _login(
      () => bloc.restoreAccount(pending, afterOnboarding: _afterOnboarding),
    );
  }
}
