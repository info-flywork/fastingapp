import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// İkonun metne göre konumu.
enum AppButtonIconPosition { leading, trailing }

/// Paylaşılan birincil CTA butonu.
///
/// Dekorasyon [AppButtonDecoration] üzerinden gelir; tipografi ve ikon
/// parametrelerle override edilebilir.
///
/// ```dart
/// AppButton(
///   label: 'Get Started',
///   onPressed: () {},
/// )
///
/// AppButton(
///   label: 'Continue',
///   onPressed: () {},
///   showIcon: false,
///   fontSize: 16,
/// )
/// ```
final class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.decoration,
    this.fontSize,
    this.iconAsset,
    this.icon,
    this.iconSize = 20,
    this.iconPosition = AppButtonIconPosition.trailing,
    this.showIcon = true,
    this.isEnabled = true,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  /// null ise [AppButtonDecoration.primary] kullanılır.
  final AppButtonDecoration? decoration;

  /// null ise dekorasyonun defaultFontSize değeri (18) kullanılır.
  final double? fontSize;

  /// Özel asset yolu. null + [showIcon] true → varsayılan ok ikonu.
  final String? iconAsset;

  /// Verilirse asset yerine bu widget çizilir.
  final Widget? icon;

  final double iconSize;
  final AppButtonIconPosition iconPosition;

  /// false → hiç ikon gösterilmez.
  final bool showIcon;
  final bool isEnabled;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final style = decoration ?? AppButtonDecoration.primary();
    final enabled = isEnabled && onPressed != null;
    final iconWidget = _resolveIcon(style);

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (iconWidget != null &&
            iconPosition == AppButtonIconPosition.leading) ...[
          iconWidget,
          SizedBox(width: style.gap),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style.labelStyle(fontSize: fontSize),
          ),
        ),
        if (iconWidget != null &&
            iconPosition == AppButtonIconPosition.trailing) ...[
          SizedBox(width: style.gap),
          iconWidget,
        ],
      ],
    );

    final button = style.buildContainer(child: content);

    return SizedBox(
      width: expand ? double.infinity : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: style.borderRadius,
            child: button,
          ),
        ),
      ),
    );
  }

  Widget? _resolveIcon(AppButtonDecoration style) {
    if (!showIcon) return null;
    if (icon != null) return icon;
    final asset = iconAsset ?? Assets.icons.solarArrowLeftLinear.path;
    return SvgPicture.asset(
      asset,
      width: iconSize,
      height: iconSize,
      colorFilter: ColorFilter.mode(style.labelColor, BlendMode.srcIn),
    );
  }
}
