part of '../splash_view.dart';

/// Splash logosu — uygulama ikonu (16 radius).
final class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AppImages.appIcon.image(width: 96, height: 96, fit: BoxFit.cover),
    );
  }
}
