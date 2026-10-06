import 'package:flutter/material.dart';

/// Tüm dialog UI'larının ortak kabuğu.
final class BaseDialog extends StatelessWidget {
  const BaseDialog({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }
}
