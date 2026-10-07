import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Onay dialog'u: rozet ikon, başlık, açıklama, onay (sol) / vazgeç (sağ).
/// Onayda `true`, vazgeçte `false` döner.
final class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    required this.icon,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
    super.key,
  });

  final SvgGenImage icon;
  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;

  static const _badgeSize = 72.0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: _badgeSize / 2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ColorName.colorWhite,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.fastingEndTitle,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.fastingEndBody,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: confirmLabel,
                            onPressed: () => Navigator.of(context).pop(true),
                            showIcon: false,
                            decoration: AppButtonDecoration.endFastCancel(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppButton(
                            label: cancelLabel,
                            onPressed: () => Navigator.of(context).pop(false),
                            showIcon: false,
                            decoration: AppButtonDecoration.homeJoin(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          _Badge(icon: icon),
        ],
      ),
    );
  }
}

final class _Badge extends StatelessWidget {
  const _Badge({required this.icon});

  final SvgGenImage icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ConfirmDialog._badgeSize,
      height: ConfirmDialog._badgeSize,
      decoration: BoxDecoration(
        color: ColorName.colorProfileBack,
        shape: BoxShape.circle,
        border: Border.all(color: ColorName.colorWhite, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: icon.svg(
        width: 28,
        height: 28,
        colorFilter: const ColorFilter.mode(
          ColorName.colorOptionNegative,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
