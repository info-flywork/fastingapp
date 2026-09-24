import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Oruç başlangıç saati — tarih, saat ve dakika tekerleği.
final class FastingStartSheet extends StatefulWidget {
  const FastingStartSheet({required this.initial, super.key});

  final DateTime initial;

  @override
  State<FastingStartSheet> createState() => _FastingStartSheetState();
}

class _FastingStartSheetState extends State<FastingStartSheet> {
  static const _itemExtent = 56.0;
  static const _visibleCount = 5;
  static const _pastDays = 30;
  static const _futureDays = 14;
  static const _loopPasses = 80;
  static const _hourCount = 24;
  static const _minuteCount = 60;

  late final List<DateTime> _dates;
  late final FixedExtentScrollController _dateController;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  late int _dateIndex;
  late int _hour;
  late int _minute;

  int _toLoopIndex(int value, int itemCount) =>
      itemCount * (_loopPasses ~/ 2) + value;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _dates = [
      for (var i = -_pastDays; i <= _futureDays; i++)
        today.add(Duration(days: i)),
    ];
    final initialDay = DateUtils.dateOnly(widget.initial);
    final found = _dates.indexWhere(
      (day) => DateUtils.isSameDay(day, initialDay),
    );
    _dateIndex = found < 0 ? _pastDays : found;
    _hour = widget.initial.hour;
    _minute = widget.initial.minute;
    _dateController = FixedExtentScrollController(initialItem: _dateIndex);
    _hourController = FixedExtentScrollController(
      initialItem: _toLoopIndex(_hour, _hourCount),
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _toLoopIndex(_minute, _minuteCount),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _save() {
    final day = _dates[_dateIndex];
    Navigator.of(
      context,
    ).pop(DateTime(day.year, day.month, day.day, _hour, _minute));
  }

  String _dateLabel(int index) {
    final day = _dates[index];
    if (DateUtils.isSameDay(day, DateTime.now())) {
      return 'fasting_page.start_sheet_today'.tr();
    }
    return DateFormat('d MMM EEE', context.locale.toString()).format(day);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: ColorName.colorWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(32, 48, 32, 16 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'fasting_page.start_sheet_title'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.fastingMealTitle,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: _itemExtent * _visibleCount,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const _SelectionPill(),
                        Positioned.fill(
                          child: _WheelRow(
                            date: _ColumnWheel(
                              controller: _dateController,
                              childCount: _dates.length,
                              alignment: Alignment.centerRight,
                              labelAt: _dateLabel,
                              offsetAt: (index) => index - _dateIndex,
                              onSelected: (index) {
                                setState(() => _dateIndex = index);
                              },
                            ),
                            hour: _ColumnWheel(
                              controller: _hourController,
                              childCount: _hourCount * _loopPasses,
                              labelAt: (index) => (index % _hourCount)
                                  .toString()
                                  .padLeft(2, '0'),
                              offsetAt: (index) => _signedOffset(
                                index % _hourCount,
                                _hour,
                                _hourCount,
                              ),
                              onSelected: (index) {
                                setState(() => _hour = index % _hourCount);
                              },
                            ),
                            minute: _ColumnWheel(
                              controller: _minuteController,
                              childCount: _minuteCount * _loopPasses,
                              labelAt: (index) => (index % _minuteCount)
                                  .toString()
                                  .padLeft(2, '0'),
                              offsetAt: (index) => _signedOffset(
                                index % _minuteCount,
                                _minute,
                                _minuteCount,
                              ),
                              onSelected: (index) {
                                setState(() => _minute = index % _minuteCount);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'fasting_page.start_sheet_save'.tr(),
                    onPressed: _save,
                    showIcon: false,
                    decoration: AppButtonDecoration.fastingStartConfirm(),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(child: _Clock()),
        ),
        Positioned(
          top: 52,
          right: 16,
          child: _CloseButton(onPressed: () => Navigator.of(context).pop()),
        ),
      ],
    );
  }
}

int _signedOffset(int value, int selected, int count) {
  var delta = (value - selected) % count;
  final half = count ~/ 2;
  if (delta > half) delta -= count;
  if (delta < -half) delta += count;
  return delta;
}

final class _Clock extends StatelessWidget {
  const _Clock();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: ColoredBox(
        color: ColorName.colorWhite,
        child: Assets.images.greenClock.image(
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

final class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorPlanArcTrack,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: ColorName.colorTitle,
          ),
        ),
      ),
    );
  }
}

final class _SelectionPill extends StatelessWidget {
  const _SelectionPill();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColorName.colorProfileBack,
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          border: Border(
            top: BorderSide(
              color: ColorName.colorBlack.withValues(alpha: 0.06),
            ),
            bottom: BorderSide(
              color: ColorName.colorBlack.withValues(alpha: 0.06),
            ),
          ),
        ),
        child: const SizedBox(width: double.infinity, height: 56),
      ),
    );
  }
}

final class _WheelRow extends StatelessWidget {
  const _WheelRow({
    required this.date,
    required this.hour,
    required this.minute,
  });

  final Widget date;
  final Widget hour;
  final Widget minute;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Expanded(child: date),
        const SizedBox(width: 56),
        SizedBox(width: 36, child: hour),
        const SizedBox(width: 56),
        SizedBox(width: 36, child: minute),
        const SizedBox(width: 30),
      ],
    );
  }
}

final class _ColumnWheel extends StatelessWidget {
  const _ColumnWheel({
    required this.controller,
    required this.childCount,
    required this.labelAt,
    required this.offsetAt,
    required this.onSelected,
    this.alignment = Alignment.center,
  });

  final FixedExtentScrollController controller;
  final int childCount;
  final String Function(int index) labelAt;
  final int Function(int index) offsetAt;
  final ValueChanged<int> onSelected;
  final Alignment alignment;

  static const _itemExtent = 56.0;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _itemExtent,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 100,
      perspective: 0.0001,
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: childCount,
        builder: (context, index) {
          return Align(
            alignment: alignment,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _FadedWheelText(
                label: labelAt(index),
                offset: offsetAt(index),
              ),
            ),
          );
        },
      ),
    );
  }
}

final class _FadedWheelText extends StatelessWidget {
  const _FadedWheelText({required this.label, required this.offset});

  final String label;
  final int offset;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.fastingStartWheel;
    final text = Text(
      label,
      maxLines: 1,
      textAlign: TextAlign.center,
      style: offset == 0 ? style : style.copyWith(color: ColorName.colorWhite),
    );
    if (offset == 0) return text;
    final distance = offset.abs();
    final alpha = switch (distance) {
      1 => 0.45,
      2 => 0.22,
      _ => 0.1,
    };
    final towardSelection = offset < 0
        ? Alignment.bottomCenter
        : Alignment.topCenter;
    final away = offset < 0 ? Alignment.topCenter : Alignment.bottomCenter;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: towardSelection,
          end: away,
          colors: [
            ColorName.colorTitle.withValues(alpha: alpha),
            ColorName.colorTimePickerGradientEnd.withValues(alpha: 0),
          ],
        ).createShader(bounds);
      },
      child: text,
    );
  }
}
