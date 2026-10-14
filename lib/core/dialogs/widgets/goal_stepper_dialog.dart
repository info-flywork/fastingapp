import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Hedef düzenleme (adım / uyku): −/+ ile [min]–[max] arası, [step]
/// adımlarla. Kaydette yeni değer, vazgeçte null döner.
final class GoalStepperDialog extends StatefulWidget {
  const GoalStepperDialog({
    required this.title,
    required this.initial,
    required this.min,
    required this.max,
    required this.step,
    required this.format,
    required this.saveLabel,
    super.key,
  });

  final String title;
  final int initial;
  final int min;
  final int max;
  final int step;
  final String Function(int value) format;
  final String saveLabel;

  @override
  State<GoalStepperDialog> createState() => _GoalStepperDialogState();
}

class _GoalStepperDialogState extends State<GoalStepperDialog> {
  late int _value = widget.initial.clamp(widget.min, widget.max);

  void _change(int delta) =>
      setState(() => _value = (_value + delta).clamp(widget.min, widget.max));

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColorName.colorWhite,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.fastingEndTitle,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _StepButton(
                    icon: Icons.remove_rounded,
                    onTap: _value > widget.min
                        ? () => _change(-widget.step)
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      widget.format(_value),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.fastingEndTitle,
                    ),
                  ),
                  _StepButton(
                    icon: Icons.add_rounded,
                    onTap: _value < widget.max
                        ? () => _change(widget.step)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppButton(
                label: widget.saveLabel,
                showIcon: false,
                decoration: AppButtonDecoration.homeJoin(),
                onPressed: () => Navigator.of(context).pop(_value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorProfileBack,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: onTap == null
                ? ColorName.colorBlack.withValues(alpha: 0.2)
                : ColorName.colorTitle,
          ),
        ),
      ),
    );
  }
}
