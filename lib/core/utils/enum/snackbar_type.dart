import 'package:flutter/material.dart';

/// Snackbar tipi; renk ve ikon merkezi olarak buradan gelir.
///
/// Not: Renkler, flutter_gen üretimi tamamlandığında `ColorName` ile
/// değiştirilmelidir (doküman 9.4). Şimdilik yer tutucu Material renkleri.
enum SnackBarType {
  success(color: Color(0xFF00B894), icon: Icons.check_circle_outline),
  failure(color: Color(0xFFE30A17), icon: Icons.error_outline),
  info(color: Color(0xFF2D9CDB), icon: Icons.info_outline),
  warning(color: Color(0xFFF39C12), icon: Icons.warning_amber_outlined);

  const SnackBarType({required this.color, required this.icon});

  final Color color;
  final IconData icon;
}

/// Snackbar'ın ekranda gösterileceği konum.
enum SnackBarPosition { top, bottom }
