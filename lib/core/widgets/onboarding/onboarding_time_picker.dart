import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Saat + dakika tekerlekli seçici (HH  MM) — döngüsel (00 ↔ 59).
final class OnboardingTimePicker extends StatefulWidget {
  const OnboardingTimePicker({
    required this.label,
    required this.hour,
    required this.minute,
    required this.onHourChanged,
    required this.onMinuteChanged,
    super.key,
  });

  final String label;
  final int hour;
  final int minute;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;

  @override
  State<OnboardingTimePicker> createState() => OnboardingTimePickerState();
}

final class OnboardingTimePickerState extends State<OnboardingTimePicker> {
  /// Seçili satır: 12 + 40 (metin) + 12 divider boşluğu.
  static const _itemExtent = 64.0;
  static const _visibleCount = 3;
  static const _loopPasses = 100;

  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  /// Tekerleğin ortasında duran değer. Kayıt, son bildirimi değil bunu okur.
  int get selectedHour => _selected(_hourController, 24, widget.hour);

  int get selectedMinute => _selected(_minuteController, 60, widget.minute);

  int _selected(
    FixedExtentScrollController controller,
    int count,
    int fallback,
  ) {
    if (!controller.hasClients) return fallback;
    return controller.selectedItem % count;
  }

  int _loopCenter(int itemCount) => itemCount * (_loopPasses ~/ 2);

  int _toLoopIndex(int value, int itemCount) => _loopCenter(itemCount) + value;

  @override
  void initState() {
    super.initState();
    _hourController = FixedExtentScrollController(
      initialItem: _toLoopIndex(widget.hour, 24),
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _toLoopIndex(widget.minute, 60),
    );
  }

  @override
  void didUpdateWidget(covariant OnboardingTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hour != widget.hour && _hourController.hasClients) {
      final current = _hourController.selectedItem % 24;
      if (current != widget.hour) {
        _hourController.jumpToItem(_toLoopIndex(widget.hour, 24));
      }
    }
    if (oldWidget.minute != widget.minute && _minuteController.hasClients) {
      final current = _minuteController.selectedItem % 60;
      if (current != widget.minute) {
        _minuteController.jumpToItem(_toLoopIndex(widget.minute, 60));
      }
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.label,
          textAlign: TextAlign.center,
          style: AppTextStyles.timePickerLabel,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _itemExtent * _visibleCount,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Wheel(
                    controller: _hourController,
                    itemCount: 24,
                    loopPasses: _loopPasses,
                    selectedValue: widget.hour,
                    onSelected: widget.onHourChanged,
                  ),
                  const SizedBox(width: 56),
                  _Wheel(
                    controller: _minuteController,
                    itemCount: 60,
                    loopPasses: _loopPasses,
                    selectedValue: widget.minute,
                    onSelected: widget.onMinuteChanged,
                  ),
                ],
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: ColorName.colorBlack.withValues(alpha: 0.05),
                      ),
                      bottom: BorderSide(
                        color: ColorName.colorBlack.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: const SizedBox(
                    width: double.infinity,
                    height: _itemExtent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.itemCount,
    required this.loopPasses,
    required this.selectedValue,
    required this.onSelected,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final int loopPasses;
  final int selectedValue;
  final ValueChanged<int> onSelected;

  static const _itemExtent = 64.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: _itemExtent,
        physics: const FixedExtentScrollPhysics(),
        diameterRatio: 100,
        perspective: 0.0001,
        onSelectedItemChanged: (index) => onSelected(index % itemCount),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount * loopPasses,
          builder: (context, index) {
            final value = index % itemCount;
            final selected = value == selectedValue;
            final text = value.toString().padLeft(2, '0');
            if (!selected) {
              return Center(
                child: Text(text, style: AppTextStyles.timePickerValueFaded),
              );
            }
            return Center(
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ColorName.colorTitle,
                    ColorName.colorTimePickerGradientEnd,
                  ],
                ).createShader(bounds),
                child: Text(text, style: AppTextStyles.timePickerValue),
              ),
            );
          },
        ),
      ),
    );
  }
}
