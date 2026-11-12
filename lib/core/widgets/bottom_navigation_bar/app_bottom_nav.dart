import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:flutter/material.dart';

/// Ana shell alt navigasyonu — ortada bar ile bütünleşik çıkıntı.
final class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _iconSize = 32.0;
  static const _mochiSize = 52.0;

  /// Figma Ellipse 160 genişliği (68). Yükseklik daha alçak → bombeli kapak.
  static const _bumpWidth = 68.0;
  static const _bumpHeight = 28.0;
  static const _cornerRadius = 12.0;
  static const _mochiIndex = 2;

  /// Figma: fill #FFFFFF %80.
  static const _barFill = Color(0xCCFFFFFF);

  /// SafeArea altı hariç bar yüksekliği — scroll içerik padding'i için.
  static const barClearance = _bumpHeight + 10 + _iconSize + 4 + 16;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final barPadBottom = bottom > 0 ? bottom : 10.0;
    const contentHeight = 10 + _iconSize + 4 + 16;
    final totalHeight = _bumpHeight + contentHeight + barPadBottom;
    const shape = _NavBarBumpShape(
      bumpWidth: _bumpWidth,
      bumpHeight: _bumpHeight,
      cornerRadius: _cornerRadius,
    );

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _NavBarShadowPainter(shape: shape)),
          ),
          Positioned.fill(
            child: ClipPath(
              clipper: const _NavBarBumpClipper(shape: shape),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: const ColoredBox(color: _barFill),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: barPadBottom,
            top: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _NavTile(
                    labelKey: 'home.nav_home',
                    icon: AppImages.home,
                    selected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                ),
                Expanded(
                  child: _NavTile(
                    labelKey: 'home.nav_fasting',
                    icon: AppImages.fasting,
                    selected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                ),
                Expanded(
                  child: _MochiTile(
                    selected: currentIndex == _mochiIndex,
                    onTap: () => onTap(_mochiIndex),
                  ),
                ),
                Expanded(
                  child: _NavTile(
                    labelKey: 'home.nav_plans',
                    icon: AppImages.plans,
                    selected: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                ),
                Expanded(
                  child: _NavTile(
                    labelKey: 'home.nav_profile',
                    icon: AppImages.profile,
                    selected: currentIndex == 4,
                    onTap: () => onTap(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _MochiTile extends StatelessWidget {
  const _MochiTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: selected ? 1 : 0.85,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(0, -10),
              child: SizedBox(
                width: AppBottomNav._mochiSize,
                height: AppBottomNav._mochiSize,
                child: AppImages.mochiWorlV2.image(fit: BoxFit.contain),
              ),
            ),
            Opacity(
              opacity: selected ? 1 : 0.5,
              child: Text(
                'home.nav_mochi_world'.tr(),
                style: AppTextStyles.navLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.labelKey,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String labelKey;
  final AppImageAsset icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: selected ? 1 : 0.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            icon.image(
              width: AppBottomNav._iconSize,
              height: AppBottomNav._iconSize,
            ),
            const SizedBox(height: 4),
            Text(
              labelKey.tr(),
              style: AppTextStyles.navLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

final class _NavBarBumpShape {
  const _NavBarBumpShape({
    required this.bumpWidth,
    required this.bumpHeight,
    required this.cornerRadius,
  });

  final double bumpWidth;
  final double bumpHeight;
  final double cornerRadius;

  Path pathFor(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final halfW = bumpWidth / 2;
    final flatTop = bumpHeight;

    return Path()
      ..moveTo(0, h)
      ..lineTo(0, flatTop + cornerRadius)
      ..quadraticBezierTo(0, flatTop, cornerRadius, flatTop)
      ..lineTo(cx - halfW, flatTop)
      // Kontrol noktaları y=0 → dışa (yukarı) bombeli kapak.
      ..cubicTo(cx - halfW * 0.55, 0, cx + halfW * 0.55, 0, cx + halfW, flatTop)
      ..lineTo(w - cornerRadius, flatTop)
      ..quadraticBezierTo(w, flatTop, w, flatTop + cornerRadius)
      ..lineTo(w, h)
      ..close();
  }
}

final class _NavBarBumpClipper extends CustomClipper<Path> {
  const _NavBarBumpClipper({required this.shape});

  final _NavBarBumpShape shape;

  @override
  Path getClip(Size size) => shape.pathFor(size);

  @override
  bool shouldReclip(covariant _NavBarBumpClipper oldClipper) =>
      oldClipper.shape.bumpWidth != shape.bumpWidth ||
      oldClipper.shape.bumpHeight != shape.bumpHeight ||
      oldClipper.shape.cornerRadius != shape.cornerRadius;
}

/// Figma drop shadow'ları (blur ≈ sigma×2).
final class _NavBarShadowPainter extends CustomPainter {
  const _NavBarShadowPainter({required this.shape});

  final _NavBarBumpShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape.pathFor(size);
    void shadow(Offset offset, double sigma, double opacity) {
      final paint = Paint()
        ..color = Colors.black.withValues(alpha: opacity)
        ..maskFilter = sigma <= 0
            ? null
            : MaskFilter.blur(BlurStyle.normal, sigma);
      canvas.drawPath(path.shift(offset), paint);
    }

    // Y:3 blur 0 → %22; Y:-1 blur 12 → %5; Y:-2 blur 8 → %5.
    shadow(const Offset(0, 3), 0, 0.22);
    shadow(const Offset(0, -1), 6, 0.05);
    shadow(const Offset(0, -2), 4, 0.05);
  }

  @override
  bool shouldRepaint(covariant _NavBarShadowPainter oldDelegate) =>
      oldDelegate.shape.bumpWidth != shape.bumpWidth ||
      oldDelegate.shape.bumpHeight != shape.bumpHeight ||
      oldDelegate.shape.cornerRadius != shape.cornerRadius;
}
