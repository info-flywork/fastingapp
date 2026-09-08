part of '../welcome_view.dart';

/// Sosyal (Google) giriş butonu.
final class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        child: Text('auth.continue_with_google'.tr()),
      ),
    );
  }
}
