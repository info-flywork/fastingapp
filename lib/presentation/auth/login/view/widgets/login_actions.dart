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
          icon: const Icon(Icons.apple, size: 22, color: ColorName.colorWhite),
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

/// Kullanım koşulları / gizlilik politikası bağlantıları (`/app/config`
/// adresleri; önceden link gibi görünüp açılmıyordu).
final class _LoginLegalText extends StatefulWidget {
  const _LoginLegalText();

  @override
  State<_LoginLegalText> createState() => _LoginLegalTextState();
}

class _LoginLegalTextState extends State<_LoginLegalText> {
  late final _terms = TapGestureRecognizer()
    ..onTap = () => _open((l) => l.termsUrl);
  late final _privacy = TapGestureRecognizer()
    ..onTap = () => _open((l) => l.privacyUrl);

  @override
  void initState() {
    super.initState();
    // Dokunmadan önce adresler hazır olsun.
    getIt<AppLinksRepository>().get().ignore();
  }

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  Future<void> _open(String? Function(AppLinks links) pick) async {
    final url = pick(await getIt<AppLinksRepository>().get());
    if (url == null) return;
    await getIt<UrlLauncherManager>().openUrl(url);
  }

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
              recognizer: _terms,
            ),
            TextSpan(text: 'auth.legal_middle'.tr()),
            TextSpan(
              text: 'auth.privacy_policy'.tr(),
              style: AppTextStyles.loginLegalLink,
              recognizer: _privacy,
            ),
            TextSpan(text: 'auth.legal_suffix'.tr()),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
