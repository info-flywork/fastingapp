import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Highlight ekranlarındaki info chip (kilit + gizlilik metni vb.).
final class OnboardingInfoChip extends StatelessWidget {
  const OnboardingInfoChip({
    required this.label,
    this.leading,
    this.labelStyle,
    this.expand = false,
    this.textAlign = TextAlign.start,
    super.key,
  });

  final String label;
  final Widget? leading;
  final TextStyle? labelStyle;

  /// `true` ise satır genişliği parent’ı doldurur (Figma Fill).
  final bool expand;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final style = labelStyle ?? AppTextStyles.infoChipLabel;
    final text = Text(label, style: style, textAlign: textAlign);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: leading == null
            ? (expand ? SizedBox(width: double.infinity, child: text) : text)
            : Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  leading!,
                  const SizedBox(width: 10),
                  Flexible(child: text),
                ],
              ),
      ),
    );
  }
}
