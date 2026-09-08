import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:flutter/material.dart';

/// Tüm snackbar gösterimlerinin tek giriş noktası. Feature katmanında
/// `ScaffoldMessenger` doğrudan kullanılmaz. (Doküman 9.4)
final class AppSnackbar {
  const AppSnackbar._();

  static void show({
    required BuildContext context,
    required String text,
    required SnackBarType type,
    SnackBarPosition position = SnackBarPosition.top,
    Duration duration = const Duration(seconds: 2),
  }) {
    // İskelet: doküman overlay tabanlı özel gösterim önerir. Şimdilik
    // ScaffoldMessenger tabanlı basit gösterim; overlay'e taşınabilir.
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: type.color,
          content: Row(
            children: [
              Icon(type.icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(text)),
            ],
          ),
        ),
      );
  }
}
