import 'package:flutter/material.dart';

/// Ortak showModalBottomSheet davranışını tanımlar. (Doküman 9.5)
abstract class BottomSheetHandler {
  Future<T?> showCustomBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: child,
      ),
    );
  }
}
