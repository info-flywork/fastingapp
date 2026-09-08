part of '../welcome_view.dart';

/// Misafir girişi butonu.
final class GuestLoginButton extends StatelessWidget {
  const GuestLoginButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        child: Text('auth.continue_as_guest'.tr()),
      ),
    );
  }
}
