import 'package:flutter/material.dart';

/// Ortak showDialog davranışını (barrier rengi, dismissible) tanımlar.
/// (Doküman 9.3)
abstract class DialogHandler {
  Future<T?> showNormalDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: .5),
      builder: (_) => child,
    );
  }
}
