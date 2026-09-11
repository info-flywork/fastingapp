part of '../entry_view.dart';

/// Get Started + hesap linki.
final class EntryActions extends StatelessWidget {
  const EntryActions({
    required this.onGetStarted,
    required this.onAlreadyHaveAccount,
    super.key,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onAlreadyHaveAccount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton(label: 'auth.get_started'.tr(), onPressed: onGetStarted),
        const SizedBox(height: 12),
        AppTextButton(
          label: 'auth.already_have_account'.tr(),
          onPressed: onAlreadyHaveAccount,
        ),
      ],
    );
  }
}
