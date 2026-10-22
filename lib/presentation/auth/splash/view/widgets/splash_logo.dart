part of '../splash_view.dart';

/// Splash markası — ikon + MochiFast.
final class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: ColorName.colorBrandStrong.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: AppImages.appIcon.image(
              width: 112,
              height: 112,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'MochiFast',
          style: TextStyle(
            fontFamily: FontFamily.sFProDisplay,
            fontWeight: FontWeight.w700,
            fontSize: 28,
            height: 1.15,
            letterSpacing: -0.6,
            color: ColorName.colorBrandStrong,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'fast together',
          style: TextStyle(
            fontFamily: FontFamily.sFProDisplay,
            fontWeight: FontWeight.w500,
            fontSize: 15,
            height: 1.2,
            letterSpacing: -0.2,
            color: ColorName.colorSubtitle.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
