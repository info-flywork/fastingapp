import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Birincil CTA butonunun Figma dekorasyonu (gradient, border, inner shadow).
///
/// Yeni varyantlar için named constructor / factory eklenir; widget tarafında
/// hex veya BoxDecoration hardcoded tutulmaz.
final class AppButtonDecoration {
  const AppButtonDecoration({
    required this.gradient,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.height,
    required this.padding,
    required this.gap,
    required this.innerShadowColor,
    required this.innerShadowOffset,
    required this.innerShadowBlur,
    required this.labelColor,
    required this.fontFamily,
    required this.fontWeight,
    required this.defaultFontSize,
    required this.lineHeight,
    required this.letterSpacingPercent,
  });

  /// Figma: Frame 48096339 — yeşil gradient pill CTA.
  factory AppButtonDecoration.primary() {
    return AppButtonDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          ColorName.colorCtaGradientTop,
          ColorName.colorCtaGradientBottom,
        ],
      ),
      borderColor: ColorName.colorWhite.withValues(alpha: 0.15),
      borderWidth: 1,
      borderRadius: BorderRadius.circular(99999),
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      gap: 8,
      innerShadowColor: ColorName.colorWhite.withValues(alpha: 0.55),
      innerShadowOffset: const Offset(0, 4),
      innerShadowBlur: 16,
      labelColor: ColorName.colorWhite,
      fontFamily: FontFamily.sFProDisplay,
      fontWeight: FontWeight.w600,
      defaultFontSize: 18,
      lineHeight: 24,
      letterSpacingPercent: -0.02,
    );
  }

  /// Highlight ekranları: beyaz pill, koyu yazı.
  factory AppButtonDecoration.onLight() {
    return AppButtonDecoration(
      gradient: const LinearGradient(
        colors: [ColorName.colorWhite, ColorName.colorWhite],
      ),
      borderColor: ColorName.colorWhite,
      borderWidth: 0,
      borderRadius: BorderRadius.circular(99999),
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      gap: 8,
      innerShadowColor: ColorName.colorWhite.withValues(alpha: 0),
      innerShadowOffset: Offset.zero,
      innerShadowBlur: 0,
      labelColor: ColorName.colorTextPrimary,
      fontFamily: FontFamily.sFProDisplay,
      fontWeight: FontWeight.w600,
      defaultFontSize: 18,
      lineHeight: 24,
      letterSpacingPercent: -0.02,
    );
  }

  /// Login Google: beyaz pill, ince border, koyu yazı.
  factory AppButtonDecoration.loginSecondary() {
    return AppButtonDecoration(
      gradient: const LinearGradient(
        colors: [ColorName.colorWhite, ColorName.colorWhite],
      ),
      borderColor: ColorName.colorWhite.withValues(alpha: 0.15),
      borderWidth: 1,
      borderRadius: BorderRadius.circular(99999),
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      gap: 8,
      innerShadowColor: ColorName.colorWhite.withValues(alpha: 0.55),
      innerShadowOffset: const Offset(0, 4),
      innerShadowBlur: 16,
      labelColor: ColorName.colorTitle,
      fontFamily: FontFamily.sFProDisplay,
      fontWeight: FontWeight.w600,
      defaultFontSize: 18,
      lineHeight: 24,
      letterSpacingPercent: -0.02,
    );
  }

  final Gradient gradient;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final double height;
  final EdgeInsets padding;
  final double gap;
  final Color innerShadowColor;
  final Offset innerShadowOffset;
  final double innerShadowBlur;
  final Color labelColor;
  final String fontFamily;
  final FontWeight fontWeight;
  final double defaultFontSize;
  final double lineHeight;
  final double letterSpacingPercent;

  TextStyle labelStyle({double? fontSize}) {
    final size = fontSize ?? defaultFontSize;
    return TextStyle(
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontSize: size,
      height: lineHeight / size,
      letterSpacing: size * letterSpacingPercent,
      color: labelColor,
    );
  }

  /// Gradient + border + üst iç gölge ile [child]'ı sarar.
  Widget buildContainer({required Widget child}) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
            // Figma inner shadow (y:4, blur:16, white 55%) — üst highlight.
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: const Alignment(0, 0.15),
                    colors: [
                      innerShadowColor,
                      innerShadowColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: Padding(padding: padding, child: child),
            ),
          ],
        ),
      ),
    );
  }
}
