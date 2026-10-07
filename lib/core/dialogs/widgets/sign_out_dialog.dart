import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/dialogs/widgets/confirm_dialog.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:flutter/material.dart';

/// Çıkış onayı. `true` dönerse oturum kapatılır.
final class SignOutDialog extends StatelessWidget {
  const SignOutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return ConfirmDialog(
      icon: Assets.icons.solarLogout2LineDuotone,
      title: 'profile.log_out_title'.tr(),
      body: 'profile.log_out_body'.tr(),
      confirmLabel: 'profile.log_out_confirm'.tr(),
      cancelLabel: 'profile.log_out_cancel'.tr(),
    );
  }
}
