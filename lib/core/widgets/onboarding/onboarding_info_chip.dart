import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Highlight ekranlarındaki info chip (kilit + gizlilik metni vb.).
final class OnboardingInfoChip extends StatelessWidget {
  const OnboardingInfoChip({
    required this.label,
    this.leading,
    this.labelStyle,
    super.key,
  });

  final String label;
  final Widget? leading;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Flexible(
              child: Text(
                label,
                style: labelStyle ?? AppTextStyles.infoChipLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
