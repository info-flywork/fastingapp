part of '../login_view.dart';

/// MochiFast logo + WELCOME + slogan.
final class LoginCopy extends StatelessWidget {
  const LoginCopy({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
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
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Yalnızca sloganın arkası — hero GIF üstüyle aynı renk, tam genişlik.
        ColoredBox(
          color: ColorName.colorLoginSloganBg,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 2, 24, 0),
            child: Text(
              'auth.login_slogan'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.loginSlogan,
            ),
          ),
        ),
      ],
    );
  }
}
