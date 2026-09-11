part of '../welcome_view.dart';

/// Karşılama ekranı navigasyon ve snackbar yardımcıları. (Doküman 5.5)
mixin WelcomeViewMixin on State<WelcomeView> {
  Future<void> onGoogle() => _login(
    () => context.read<WelcomeBloc>().loginWithGoogle(),
  );

  Future<void> onGuest() => _login(
    () => context.read<WelcomeBloc>().loginAsGuest(),
  );

  Future<void> _login(Future<String> Function() action) async {
    try {
      final navigateTo = await action().withLoading(context);
      if (!mounted) return;
      context.go(navigateTo);
    } on Exception catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context: context,
        text: e.toString(),
        type: SnackBarType.failure,
      );
    }
  }
}
