import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
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
  static const _cornerRadius = 24.0;
  static const _mochiIndex = 2;
  static const _barColor = ColorName.colorWhite;

  /// SafeArea altı hariç bar yüksekliği — scroll içerik padding'i için.
  static const barClearance = _bumpHeight + 10 + _iconSize + 4 + 16;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final barPadBottom = bottom > 0 ? bottom : 10.0;
    const contentHeight = 10 + _iconSize + 4 + 16;
    final totalHeight = _bumpHeight + contentHeight + barPadBottom;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _NavBarBumpPainter(
                bumpWidth: _bumpWidth,
                bumpHeight: _bumpHeight,
                cornerRadius: _cornerRadius,
                color: _barColor,
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
                    icon: Assets.images.home,
                    selected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                ),
                Expanded(
                  child: _NavTile(
                    labelKey: 'home.nav_fasting',
                    icon: Assets.images.fasting,
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
                    icon: Assets.images.plans,
                    selected: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                ),
                Expanded(
                  child: _NavTile(
                    labelKey: 'home.nav_profile',
                    icon: Assets.images.profile,
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
                child: Assets.images.mochiWorlV2.image(fit: BoxFit.contain),
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
  final AssetGenImage icon;
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

/// 68px genişlik × bombeli kapak — AA fringe'i outset fill ile kapatır.
final class _NavBarBumpPainter extends CustomPainter {
  const _NavBarBumpPainter({
    required this.bumpWidth,
    required this.bumpHeight,
    required this.cornerRadius,
    required this.color,
  });

  final double bumpWidth;
  final double bumpHeight;
  final double cornerRadius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Beyaz path #F6F6F6 zeminde AA ile gri saçak bırakır.
    // BlurStyle.solid şekli opak büyütür; saçak zemine karışmadan örtülür.
    final outset = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.5);

    canvas
      ..drawPath(path, outset)
      ..drawPath(path.shift(const Offset(0, -1)), fill)
      ..drawPath(path, fill);
  }

  Path _buildPath(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final halfW = bumpWidth / 2;
    final rise = bumpHeight;
    final flatTop = rise;

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

  @override
  bool shouldRepaint(covariant _NavBarBumpPainter oldDelegate) {
    return oldDelegate.bumpWidth != bumpWidth ||
        oldDelegate.bumpHeight != bumpHeight ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.color != color;
  }
}
