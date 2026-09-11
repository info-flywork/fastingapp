part of '../login_view.dart';

/// MochiFast logo + WELCOME + slogan.
final class LoginCopy extends StatelessWidget {
  const LoginCopy({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Mochi', style: AppTextStyles.loginBrand),
              TextSpan(
                text: 'Fast',
                style: AppTextStyles.loginBrand.copyWith(
                  color: ColorName.colorCtaGradientBottom,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'auth.login_welcome'.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.loginWelcome,
        ),
        const SizedBox(height: 8),
        Text(
          'auth.login_slogan'.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.loginSlogan,
        ),
      ],
    );
  }
}
