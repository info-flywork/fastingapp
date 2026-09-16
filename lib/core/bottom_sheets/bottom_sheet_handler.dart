import 'package:flutter/material.dart';

/// Ortak showModalBottomSheet davranışını tanımlar. (Doküman 9.5)
abstract class BottomSheetHandler {
  Future<T?> showCustomBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    double? heightFactor = 0.6,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        if (heightFactor == null) {
          return child;
        }
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * heightFactor,
          child: child,
        );
      },
    );
  }
}
