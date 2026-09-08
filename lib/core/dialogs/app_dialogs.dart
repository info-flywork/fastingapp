import 'package:fastingapp/core/dialogs/dialog_handler.dart';
import 'package:fastingapp/core/dialogs/widgets/sign_out_dialog.dart';
import 'package:flutter/material.dart';

/// Tüm dialog'ların tek giriş noktası (singleton). Feature katmanında
/// doğrudan `showDialog` kullanılmaz. (Doküman 9.3)
final class AppDialogs extends DialogHandler {
  AppDialogs._init();

  static final AppDialogs _instance = AppDialogs._init();

  static AppDialogs get instance => _instance;

  Future<void> showSignOut(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    return showNormalDialog<void>(
      context: context,
      child: SignOutDialog(onConfirm: onConfirm),
    );
  }
}
