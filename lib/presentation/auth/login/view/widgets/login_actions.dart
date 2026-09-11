part of '../login_view.dart';

/// Apple / Google / Guest aksiyonları.
final class LoginActions extends StatelessWidget {
  const LoginActions({
    required this.onApple,
    required this.onGoogle,
    required this.onGuest,
    super.key,
  });

  final VoidCallback onApple;
  final VoidCallback onGoogle;
  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton(
          label: 'auth.continue_with_apple'.tr(),
          onPressed: onApple,
          iconPosition: AppButtonIconPosition.leading,
          icon: const Icon(
            Icons.apple,
            size: 22,
            color: ColorName.colorWhite,
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99999),
            boxShadow: [
              BoxShadow(
                color: ColorName.colorTitle.withValues(alpha: 0.1),
                offset: const Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
          child: AppButton(
            label: 'auth.continue_with_google'.tr(),
            onPressed: onGoogle,
            decoration: AppButtonDecoration.loginSecondary(),
            iconPosition: AppButtonIconPosition.leading,
            icon: SvgPicture.asset(
              Assets.icons.googleG.path,
              width: 20,
              height: 20,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const _LoginOrDivider(),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onGuest,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'auth.continue_as_guest'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.loginGuest,
            ),
          ),
        ),
      ],
    );
  }
}

final class _LoginOrDivider extends StatelessWidget {
  const _LoginOrDivider();

  static const _lineWidth = 72.0;

  @override
  Widget build(BuildContext context) {
    final lineColor = ColorName.colorTitle.withValues(alpha: 0.1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: _lineWidth,
          child: Divider(color: lineColor, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('auth.or'.tr(), style: AppTextStyles.loginOr),
        ),
        SizedBox(
          width: _lineWidth,
          child: Divider(color: lineColor, thickness: 1),
        ),
      ],
    );
  }
}

final class _LoginLegalText extends StatelessWidget {
  const _LoginLegalText();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text.rich(
        TextSpan(
          style: AppTextStyles.loginLegal,
          children: [
            TextSpan(text: 'auth.legal_prefix'.tr()),
            TextSpan(
              text: 'auth.terms_of_service'.tr(),
              style: AppTextStyles.loginLegalLink,
            ),
            TextSpan(text: 'auth.legal_middle'.tr()),
            TextSpan(
              text: 'auth.privacy_policy'.tr(),
              style: AppTextStyles.loginLegalLink,
            ),
            TextSpan(text: 'auth.legal_suffix'.tr()),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
