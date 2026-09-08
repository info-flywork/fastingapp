import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Uygulama teması. Renkler [ColorName], fontlar [FontFamily] üzerinden gelir.
/// (Doküman 9.2)
final class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: FontFamily.sFProDisplay,
    scaffoldBackgroundColor: ColorName.colorProfileBack,
    colorScheme: const ColorScheme.light(
      primary: ColorName.colorPrimaryBlue,
      error: ColorName.colorErrorRed,
    ),
    textTheme: const TextTheme(
      // Figma Semibold → FontWeight.w600 (Bold upright OTF)
      displaySmall: TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w600,
        fontSize: 32,
        height: 40 / 32,
        letterSpacing: -0.5,
        color: ColorName.colorTitle,
      ),
      bodyLarge: TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w500,
        fontSize: 20,
        height: 28 / 20,
        letterSpacing: -0.5,
        color: ColorName.colorSubtitle,
      ),
      labelLarge: TextStyle(
        fontFamily: FontFamily.sFProDisplay,
        fontWeight: FontWeight.w600,
        fontSize: 18,
        height: 24 / 18,
        letterSpacing: 18 * -0.02,
        color: ColorName.colorTextPrimary,
      ),
    ),
  );
}
