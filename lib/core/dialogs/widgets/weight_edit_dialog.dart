import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum WeightUnit { lb, kg }

/// Kilo düzenleme dialog sonucu — her zaman kg cinsinden.
@immutable
final class WeightEditResult {
  const WeightEditResult({required this.weightKg});

  final double weightKg;
}

/// Profil kilo düzenleme dialog'u (Figma Weight modal).
final class WeightEditDialog extends StatefulWidget {
  const WeightEditDialog({required this.initialWeightKg, super.key});

  final double initialWeightKg;

  static const double _kgToLb = 2.2046226218;

  @override
  State<WeightEditDialog> createState() => _WeightEditDialogState();
}

class _WeightEditDialogState extends State<WeightEditDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final AnimationController _valueAnim;
  late final Animation<double> _valueScale;
  late final Animation<double> _valueOpacity;
  WeightUnit _unit = WeightUnit.kg;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.initialWeightKg));
    _valueAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    final curved = CurvedAnimation(
      parent: _valueAnim,
      curve: Curves.easeOutCubic,
    );
    _valueScale = Tween<double>(begin: 0.92, end: 1).animate(curved);
    _valueOpacity = Tween<double>(begin: 0.4, end: 1).animate(curved);
    _valueAnim.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    _valueAnim.dispose();
    super.dispose();
  }

  String _format(double value) {
    final rounded = (value * 10).round() / 10;
    if (rounded == rounded.roundToDouble()) {
      return rounded.toStringAsFixed(0);
    }
    return rounded.toStringAsFixed(1);
  }

  double? _parseDisplayed() {
    final raw = _controller.text.replaceAll(',', '.').trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  double? _weightInKg() {
    final value = _parseDisplayed();
    if (value == null) return null;
    return _unit == WeightUnit.kg ? value : value / WeightEditDialog._kgToLb;
  }

  void _onUnitChanged(WeightUnit next) {
    if (next == _unit) return;
    final current = _parseDisplayed();
    setState(() {
      if (current != null) {
        final converted = next == WeightUnit.kg
            ? current / WeightEditDialog._kgToLb
            : current * WeightEditDialog._kgToLb;
        _controller.text = _format(converted);
      }
      _unit = next;
    });
    _valueAnim.forward(from: 0);
  }

  void _onSave() {
    final kg = _weightInKg();
    if (kg == null || kg <= 0) return;
    Navigator.of(context).pop(WeightEditResult(weightKg: kg));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 36),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ColorName.colorWhite,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'profile.weight_title'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.weightDialogTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'profile.weight_today'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.weightDialogSubtitle,
                    ),
                    const SizedBox(height: 24),
                    _WeightUnitToggle(unit: _unit, onChanged: _onUnitChanged),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _valueOpacity,
                      child: ScaleTransition(
                        scale: _valueScale,
                        child: _WeightValueField(
                          controller: _controller,
                          unit: _unit,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'profile.save'.tr(),
                      onPressed: _onSave,
                      showIcon: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ColorName.colorFlipClock,
                shape: BoxShape.circle,
                border: Border.all(color: ColorName.colorWhite, width: 3),
              ),
              clipBehavior: Clip.antiAlias,
              child: AppImages.weigher2.image(
                fit: BoxFit.cover,
                width: 72,
                height: 72,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _WeightUnitToggle extends StatelessWidget {
  const _WeightUnitToggle({required this.unit, required this.onChanged});

  final WeightUnit unit;
  final ValueChanged<WeightUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorUnitToggleBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: 28,
          width: 110,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final segmentWidth = (constraints.maxWidth - 8) / 2;
              return Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOutCubic,
                    alignment: unit == WeightUnit.lb
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      width: segmentWidth,
                      height: 28,
                      decoration: BoxDecoration(
                        color: ColorName.colorWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: ColorName.colorBlack.withValues(alpha: 0.05),
                            offset: const Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _UnitToggleLabel(
                          label: 'profile.unit_lb'.tr(),
                          selected: unit == WeightUnit.lb,
                          onTap: () => onChanged(WeightUnit.lb),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _UnitToggleLabel(
                          label: 'profile.unit_kg'.tr(),
                          selected: unit == WeightUnit.kg,
                          onTap: () => onChanged(WeightUnit.kg),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _UnitToggleLabel extends StatelessWidget {
  const _UnitToggleLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: AppTextStyles.weightDialogUnitLabel.copyWith(
            color: selected
                ? ColorName.colorTitle
                : ColorName.colorSubtitle.withValues(alpha: 0.6),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

final class _WeightValueField extends StatelessWidget {
  const _WeightValueField({required this.controller, required this.unit});

  final TextEditingController controller;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final unitLabel = unit == WeightUnit.kg
        ? 'profile.unit_kg'.tr()
        : 'profile.unit_lb'.tr();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ColorName.colorBlack.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          IntrinsicWidth(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              textAlign: TextAlign.center,
              style: AppTextStyles.weightDialogValue,
              cursorColor: ColorName.colorBrandStrong,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              unitLabel,
              key: ValueKey(unit),
              style: AppTextStyles.weightDialogValueUnit,
            ),
          ),
        ],
      ),
    );
  }
}
