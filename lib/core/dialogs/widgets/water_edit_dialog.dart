import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum WaterVolumeUnit { ml, oz }

/// Su miktarı dialog sonucu — her zaman ml.
@immutable
final class WaterValueEditResult {
  const WaterValueEditResult({required this.valueMl, required this.unit});

  final int valueMl;
  final WaterVolumeUnit unit;
}

/// Su birimi dialog sonucu.
@immutable
final class WaterUnitEditResult {
  const WaterUnitEditResult({required this.unit});

  final WaterVolumeUnit unit;
}

/// Günlük hedef / özel bardak boyutu — Weight dialog düzeni.
final class WaterValueEditDialog extends StatefulWidget {
  const WaterValueEditDialog({
    required this.titleKey,
    required this.subtitleKey,
    required this.initialValueMl,
    required this.initialUnit,
    required this.headerImage,
    super.key,
  });

  final String titleKey;
  final String subtitleKey;
  final int initialValueMl;
  final WaterVolumeUnit initialUnit;
  final AppImageAsset headerImage;

  static const double _mlPerOz = 29.5735295625;

  @override
  State<WaterValueEditDialog> createState() => _WaterValueEditDialogState();
}

class _WaterValueEditDialogState extends State<WaterValueEditDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final AnimationController _valueAnim;
  late final Animation<double> _valueScale;
  late final Animation<double> _valueOpacity;
  late WaterVolumeUnit _unit;

  @override
  void initState() {
    super.initState();
    _unit = widget.initialUnit;
    _controller = TextEditingController(
      text: _format(_toDisplay(widget.initialValueMl, _unit)),
    );
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

  double _toDisplay(int ml, WaterVolumeUnit unit) {
    if (unit == WaterVolumeUnit.ml) return ml.toDouble();
    return ml / WaterValueEditDialog._mlPerOz;
  }

  String _format(double value) {
    if (_unit == WaterVolumeUnit.ml) {
      return value.round().toString();
    }
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

  int? _valueInMl() {
    final value = _parseDisplayed();
    if (value == null || value <= 0) return null;
    if (_unit == WaterVolumeUnit.ml) return value.round();
    return (value * WaterValueEditDialog._mlPerOz).round();
  }

  void _onUnitChanged(WaterVolumeUnit next) {
    if (next == _unit) return;
    final current = _parseDisplayed();
    setState(() {
      if (current != null) {
        final ml = _unit == WaterVolumeUnit.ml
            ? current
            : current * WaterValueEditDialog._mlPerOz;
        _controller.text = _format(_toDisplay(ml.round(), next));
      }
      _unit = next;
    });
    _valueAnim.forward(from: 0);
  }

  void _onSave() {
    final ml = _valueInMl();
    if (ml == null) return;
    Navigator.of(context).pop(WaterValueEditResult(valueMl: ml, unit: _unit));
  }

  @override
  Widget build(BuildContext context) {
    return _WaterDialogShell(
      headerImage: widget.headerImage,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.titleKey.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.weightDialogTitle,
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitleKey.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.weightDialogSubtitle,
          ),
          const SizedBox(height: 24),
          _WaterUnitToggle(unit: _unit, onChanged: _onUnitChanged),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _valueOpacity,
            child: ScaleTransition(
              scale: _valueScale,
              child: _WaterValueField(controller: _controller, unit: _unit),
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'water_reminder.save_short'.tr(),
            onPressed: _onSave,
            showIcon: false,
            decoration: AppButtonDecoration.water(),
          ),
        ],
      ),
    );
  }
}

/// Birim seçimi — Weight dialog düzeni (toggle + kaydet).
final class WaterUnitEditDialog extends StatefulWidget {
  const WaterUnitEditDialog({required this.initialUnit, super.key});

  final WaterVolumeUnit initialUnit;

  @override
  State<WaterUnitEditDialog> createState() => _WaterUnitEditDialogState();
}

class _WaterUnitEditDialogState extends State<WaterUnitEditDialog> {
  late WaterVolumeUnit _unit = widget.initialUnit;

  void _onSave() {
    Navigator.of(context).pop(WaterUnitEditResult(unit: _unit));
  }

  @override
  Widget build(BuildContext context) {
    return _WaterDialogShell(
      headerImage: AppImages.waterBottle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'water_reminder.units'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.weightDialogTitle,
          ),
          const SizedBox(height: 4),
          Text(
            'water_reminder.unit_dialog_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.weightDialogSubtitle,
          ),
          const SizedBox(height: 24),
          _WaterUnitToggle(
            unit: _unit,
            onChanged: (next) => setState(() => _unit = next),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'water_reminder.save_short'.tr(),
            onPressed: _onSave,
            showIcon: false,
            decoration: AppButtonDecoration.water(),
          ),
        ],
      ),
    );
  }
}

final class _WaterDialogShell extends StatelessWidget {
  const _WaterDialogShell({required this.headerImage, required this.child});

  final AppImageAsset headerImage;
  final Widget child;

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
                child: child,
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
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: headerImage.image(fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _WaterUnitToggle extends StatelessWidget {
  const _WaterUnitToggle({required this.unit, required this.onChanged});

  final WaterVolumeUnit unit;
  final ValueChanged<WaterVolumeUnit> onChanged;

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
                    alignment: unit == WaterVolumeUnit.ml
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
                          label: 'water_reminder.unit_ml'.tr(),
                          selected: unit == WaterVolumeUnit.ml,
                          onTap: () => onChanged(WaterVolumeUnit.ml),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _UnitToggleLabel(
                          label: 'water_reminder.unit_oz'.tr(),
                          selected: unit == WaterVolumeUnit.oz,
                          onTap: () => onChanged(WaterVolumeUnit.oz),
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

final class _WaterValueField extends StatelessWidget {
  const _WaterValueField({required this.controller, required this.unit});

  final TextEditingController controller;
  final WaterVolumeUnit unit;

  @override
  Widget build(BuildContext context) {
    final unitLabel = unit == WaterVolumeUnit.ml
        ? 'water_reminder.unit_ml'.tr()
        : 'water_reminder.unit_oz'.tr();

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
              cursorColor: ColorName.colorWaterAction,
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
