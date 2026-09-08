import 'package:fastingapp/core/widgets/app_text_button_style.dart';
import 'package:flutter/material.dart';

/// Paylaşılan metin (link) butonu.
///
/// Stil [AppTextButtonStyle] üzerinden gelir; tipografi parametrelerle
/// override edilebilir.
///
/// ```dart
/// AppTextButton(
///   label: 'I already have an account',
///   onPressed: () {},
/// )
///
/// AppTextButton(
///   label: 'Skip',
///   onPressed: () {},
///   fontSize: 16,
/// )
/// ```
final class AppTextButton extends StatelessWidget {
  const AppTextButton({
    required this.label,
    required this.onPressed,
    this.style,
    this.fontSize,
    this.color,
    this.isEnabled = true,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  /// null ise [AppTextButtonStyle.primary] kullanılır.
  final AppTextButtonStyle? style;

  /// null ise stilin defaultFontSize değeri (18) kullanılır.
  final double? fontSize;

  /// null ise stilin labelColor değeri kullanılır.
  final Color? color;

  final bool isEnabled;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = style ?? const AppTextButtonStyle.primary();
    final enabled = isEnabled && onPressed != null;

    return SizedBox(
      width: expand ? double.infinity : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: color ?? buttonStyle.labelColor,
            padding: buttonStyle.padding,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: buttonStyle.labelStyle(fontSize: fontSize, color: color),
          ),
        ),
      ),
    );
  }
}
