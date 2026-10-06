import 'dart:async';

import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Onboarding sayı artır/azalt alanı.
///
/// Label üstte; altta gri kutuda: [−] değer birim [+]
/// Basılı tutunca hızlı tekrar eder.
final class OnboardingStepperField extends StatelessWidget {
  const OnboardingStepperField({
    required this.label,
    required this.displayValue,
    required this.onDecrement,
    required this.onIncrement,
    this.unit,
    this.accentValue = false,
    super.key,
  });

  final String label;
  final String displayValue;
  final String? unit;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool accentValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.stepperLabel),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: ColorName.colorBlack.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _RoundIconButton(
                  assetPath: Assets.icons.icRoundMinus.path,
                  onPressed: onDecrement,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        displayValue,
                        style: accentValue
                            ? AppTextStyles.stepperValueAccent
                            : AppTextStyles.stepperValue,
                      ),
                      if (unit != null) ...[
                        const SizedBox(width: 4),
                        Text(unit!, style: AppTextStyles.stepperUnit),
                      ],
                    ],
                  ),
                ),
                _RoundIconButton(
                  assetPath: Assets.icons.uilPlus.path,
                  onPressed: onIncrement,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _RoundIconButton extends StatefulWidget {
  const _RoundIconButton({required this.assetPath, required this.onPressed});

  final String assetPath;
  final VoidCallback onPressed;

  @override
  State<_RoundIconButton> createState() => _RoundIconButtonState();
}

class _RoundIconButtonState extends State<_RoundIconButton> {
  Timer? _repeatTimer;

  void _startRepeat() {
    widget.onPressed();
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(
      const Duration(milliseconds: 70),
      (_) => widget.onPressed(),
    );
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorWhite,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: ColorName.colorBlack.withValues(alpha: 0.12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onLongPressStart: (_) => _startRepeat(),
        onLongPressEnd: (_) => _stopRepeat(),
        onLongPressCancel: _stopRepeat,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: SvgPicture.asset(
              widget.assetPath,
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                ColorName.colorTitle,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
