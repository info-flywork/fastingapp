part of '../login_view.dart';

/// Login mascot GIF — ekran genişliğine sığar, üstü kesilmez.
/// Yazılar dil dosyasına gömülü: `mascot_login_{locale}.gif`.
final class LoginHero extends StatelessWidget {
  const LoginHero({super.key});

  static AssetGenImage assetFor(Locale locale) => switch (locale.languageCode) {
    'tr' => Assets.gifs.mascotLoginTr,
    'de' => Assets.gifs.mascotLoginDe,
    'es' => Assets.gifs.mascotLoginEs,
    'fr' => Assets.gifs.mascotLoginFr,
    'it' => Assets.gifs.mascotLoginIt,
    'ru' => Assets.gifs.mascotLoginRu,
    _ => Assets.gifs.mascotLoginEn,
  };

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(context.locale);
    return ClipRect(
      child: SizedBox.expand(
        child: asset.image(
          key: ValueKey(asset.path),
          width: double.infinity,
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }
}
