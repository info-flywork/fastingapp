import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Metin butonu tipografisi / padding. Yeni varyantlar factory ile eklenir.
final class AppTextButtonStyle {
  const AppTextButtonStyle({
    required this.labelColor,
    required this.fontFamily,
    required this.fontWeight,
    required this.defaultFontSize,
    required this.lineHeight,
    required this.letterSpacingPercent,
    required this.padding,
  });

  /// Figma: "I already have an account" — birincil metin linki.
  const AppTextButtonStyle.primary()
      : labelColor = ColorName.colorTextPrimary,
        fontFamily = FontFamily.sFProDisplay,
        fontWeight = FontWeight.w600,
        defaultFontSize = 18,
        lineHeight = 24,
        letterSpacingPercent = -0.02,
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  final Color labelColor;
  final String fontFamily;
  final FontWeight fontWeight;
  final double defaultFontSize;
  final double lineHeight;
  final double letterSpacingPercent;
  final EdgeInsets padding;

  TextStyle labelStyle({double? fontSize, Color? color}) {
    final size = fontSize ?? defaultFontSize;
    return TextStyle(
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontSize: size,
      height: lineHeight / size,
      letterSpacing: size * letterSpacingPercent,
      color: color ?? labelColor,
    );
  }
}
