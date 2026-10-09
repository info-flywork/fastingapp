import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Snackbar tipi; renk ve ikon merkezi olarak buradan gelir. (Doküman 9.4)
enum SnackBarType {
  success(
    color: ColorName.colorSuccessGreen,
    icon: Icons.check_rounded,
  ),
  failure(
    color: ColorName.colorErrorRed,
    icon: Icons.close_rounded,
  ),
  info(
    color: ColorName.colorBmi1,
    icon: Icons.info_rounded,
  ),
  warning(
    color: ColorName.colorWarningOrange,
    icon: Icons.priority_high_rounded,
  );

  const SnackBarType({required this.color, required this.icon});

  final Color color;
  final IconData icon;
}

/// Snackbar'ın ekranda gösterileceği konum.
enum SnackBarPosition { top, bottom }
