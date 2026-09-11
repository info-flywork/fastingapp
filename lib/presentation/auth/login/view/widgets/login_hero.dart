part of '../login_view.dart';

/// Login mascot GIF — ekran genişliğine sığar, üstü kesilmez.
final class LoginHero extends StatelessWidget {
  const LoginHero({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox.expand(
        child: Assets.gifs.mascotLogin.image(
          width: double.infinity,
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }
}
