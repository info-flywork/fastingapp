import 'package:fastingapp/core/dialogs/widgets/base_dialog.dart';
import 'package:flutter/material.dart';

/// Çıkış onayı dialog'u.
final class SignOutDialog extends StatelessWidget {
  const SignOutDialog({required this.onConfirm, super.key});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Çıkış yapmak istediğine emin misin?'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                child: const Text('Çıkış yap'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
