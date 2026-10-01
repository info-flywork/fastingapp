import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/flip_clock_unit.dart';
import 'package:fastingapp/core/widgets/weight_progress_bar.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Oruç bitirme özeti sayfasına taşınan plan ve süre.
@immutable
final class FastingFinishArgs {
  const FastingFinishArgs({
    required this.planTitle,
    required this.start,
    required this.end,
  });

  final String planTitle;
  final DateTime start;
  final DateTime end;
}

/// Oruç bitince açılan süre / kilo özeti — CaloriesTracker benzeri.
final class FastingFinishView extends StatefulWidget {
  const FastingFinishView({required this.args, super.key});

  final FastingFinishArgs args;

  @override
  State<FastingFinishView> createState() => _FastingFinishViewState();
}

class _FastingFinishViewState extends State<FastingFinishView> {
  static const _cardOverlap = 80.0;
  static const _currentKg = 102.5;
  static const _startKg = 112.2;
  static const _goalKg = 75.2;

  late DateTime _start;
  late DateTime _end;
  var _editingStart = false;
  var _editingEnd = false;

  @override
  void initState() {
    super.initState();
    _start = widget.args.start;
    _end = widget.args.end;
  }

  Duration get _elapsed {
    final diff = _end.difference(_start);
    return diff.isNegative ? Duration.zero : diff;
  }

  void _toggleStart() {
    setState(() {
      _editingStart = !_editingStart;
      _editingEnd = false;
    });
  }

  void _toggleEnd() {
    setState(() {
      _editingEnd = !_editingEnd;
      _editingStart = false;
    });
  }

  Future<void> _editWeight() async {
    await AppDialogs.instance.showEditWeight(
      context,
      initialWeightKg: _currentKg,
    );
  }

  String _clockLabel(DateTime value) {
    final locale = context.locale.toString();
    final day = DateUtils.isSameDay(value, DateTime.now())
        ? 'fasting_page.start_sheet_today'.tr()
        : DateFormat('d MMM', locale).format(value);
    final clock = context.locale.languageCode == 'en'
        ? DateFormat('h:mm a', locale).format(value)
        : DateFormat('HH:mm', locale).format(value);
    return '$day, $clock';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width;
    final headerHeight = width * _FinishHeader.imageAspect;
    final progress = ((_startKg - _currentKg) / (_startKg - _goalKg)).clamp(
      0.0,
      1.0,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorBodyPageBg,
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _FinishHeader(
                  topInset: top,
                  elapsed: _elapsed,
                  height: headerHeight,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: headerHeight - _cardOverlap + 24),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FastingTimesCard(
                          planTitle: widget.args.planTitle,
                          startLabel: _clockLabel(_start),
                          endLabel: _clockLabel(_end),
                          editingStart: _editingStart,
                          editingEnd: _editingEnd,
                          start: _start,
                          end: _end,
                          onToggleStart: _toggleStart,
                          onToggleEnd: _toggleEnd,
                          onStartChanged: (value) {
                            setState(() {
                              _start = value;
                              if (!_end.isAfter(_start)) {
                                _end = _start.add(const Duration(hours: 16));
                              }
                            });
                          },
                          onEndChanged: (value) {
                            setState(() {
                              _end = value.isAfter(_start)
                                  ? value
                                  : _start.add(const Duration(minutes: 1));
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _CurrentWeightCard(
                          currentKg: _currentKg,
                          startKg: _startKg,
                          goalKg: _goalKg,
                          progress: progress,
                          onEdit: _editWeight,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _FinishHeader extends StatelessWidget {
  const _FinishHeader({
    required this.topInset,
    required this.elapsed,
    required this.height,
  });

  final double topInset;
  final Duration elapsed;
  final double height;

  static const _mascotSize = 168.0;

  /// header_back.png — 1448×1086
  static const imageAspect = 1086 / 1448;

  @override
  Widget build(BuildContext context) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Assets.images.headerBack.image(
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),

          Positioned(
            left: 4,
            top: topInset,
            child: Transform.scale(
              scale: 1.1,
              child: Assets.images.caloriesTracker.image(
                width: _mascotSize,
                height: _mascotSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          Positioned(
            left: _mascotSize,
            top: topInset + 24,
            right: 16,
            child: Column(
              children: [
                Text(
                  'fasting_page.finish_total'.tr(),
                  style: AppTextStyles.caloriesEatenLabel,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FlipClockUnit(value: hours, label: 'home.timer_hrs'.tr()),
                    const SizedBox(width: 10),
                    FlipClockUnit(value: minutes, label: 'home.timer_min'.tr()),
                    const SizedBox(width: 10),
                    FlipClockUnit(value: seconds, label: 'home.timer_sec'.tr()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _FastingTimesCard extends StatelessWidget {
  const _FastingTimesCard({
    required this.planTitle,
    required this.startLabel,
    required this.endLabel,
    required this.editingStart,
    required this.editingEnd,
    required this.start,
    required this.end,
    required this.onToggleStart,
    required this.onToggleEnd,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final String planTitle;
  final String startLabel;
  final String endLabel;
  final bool editingStart;
  final bool editingEnd;
  final DateTime start;
  final DateTime end;
  final VoidCallback onToggleStart;
  final VoidCallback onToggleEnd;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<DateTime> onEndChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: ColorName.colorMealPositive,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      ColorName.colorWhite,
                      BlendMode.srcATop,
                    ),
                    child: Assets.images.forkClosest.image(
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'fasting_page.finish_plan'.tr(args: [planTitle]),
                    style: AppTextStyles.caloriesCardTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _TimeRow(
              positive: true,
              label: 'fasting_page.finish_start'.tr(),
              value: startLabel,
              onEdit: onToggleStart,
            ),
            if (editingStart) ...[
              const SizedBox(height: 12),
              _InlineTimePicker(initial: start, onChanged: onStartChanged),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: ColorName.colorFlipClock,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'fasting_page.finish_hint'.tr(),
                    style: AppTextStyles.fastingFinishHint,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 1,
              color: ColorName.colorBlack.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 16),
            _TimeRow(
              positive: false,
              label: 'fasting_page.finish_end'.tr(),
              value: endLabel,
              onEdit: onToggleEnd,
            ),
            if (editingEnd) ...[
              const SizedBox(height: 12),
              _InlineTimePicker(initial: end, onChanged: onEndChanged),
            ],
          ],
        ),
      ),
    );
  }
}

final class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.positive,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final bool positive;
  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final ring = positive
        ? ColorName.colorMealPositive
        : ColorName.colorNegativeV2;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: ColorName.colorWhite,
            shape: BoxShape.circle,
            border: Border.all(color: ring, width: 2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: AppTextStyles.fastingFinishRowLabel),
        ),
        Text(value, style: AppTextStyles.fastingFinishRowValue),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onEdit,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Assets.images.solarPenBold1.image(
              width: 18,
              height: 18,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

final class _InlineTimePicker extends StatefulWidget {
  const _InlineTimePicker({required this.initial, required this.onChanged});

  final DateTime initial;
  final ValueChanged<DateTime> onChanged;

  @override
  State<_InlineTimePicker> createState() => _InlineTimePickerState();
}

class _InlineTimePickerState extends State<_InlineTimePicker> {
  static const _itemExtent = 40.0;
  static const _pastDays = 14;
  static const _futureDays = 7;

  late final List<DateTime> _dates;
  late final FixedExtentScrollController _dateController;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  late int _dateIndex;
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _dates = [
      for (var i = -_pastDays; i <= _futureDays; i++)
        today.add(Duration(days: i)),
    ];
    final day = DateUtils.dateOnly(widget.initial);
    final found = _dates.indexWhere((d) => DateUtils.isSameDay(d, day));
    _dateIndex = found < 0 ? _pastDays : found;
    _hour = widget.initial.hour;
    _minute = widget.initial.minute;
    _dateController = FixedExtentScrollController(initialItem: _dateIndex);
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _emit() {
    final day = _dates[_dateIndex];
    widget.onChanged(DateTime(day.year, day.month, day.day, _hour, _minute));
  }

  String _dateLabel(int index) {
    final day = _dates[index];
    if (DateUtils.isSameDay(day, DateTime.now())) {
      return 'fasting_page.start_sheet_today'.tr();
    }
    return DateFormat('d MMM E', context.locale.toString()).format(day);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: ColorName.colorFlipClock,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(height: 40, width: double.infinity),
          ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ListWheelScrollView.useDelegate(
                  controller: _dateController,
                  itemExtent: _itemExtent,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() => _dateIndex = index);
                    _emit();
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _dates.length,
                    builder: (context, index) {
                      final selected = index == _dateIndex;
                      return Center(
                        child: Text(
                          _dateLabel(index),
                          style: selected
                              ? AppTextStyles.fastingFinishRowLabel
                              : AppTextStyles.fastingFinishPickerMuted,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  controller: _hourController,
                  itemExtent: _itemExtent,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() => _hour = index);
                    _emit();
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 24,
                    builder: (context, index) {
                      final selected = index == _hour;
                      return Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: selected
                              ? AppTextStyles.fastingFinishRowLabel
                              : AppTextStyles.fastingFinishPickerMuted,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  controller: _minuteController,
                  itemExtent: _itemExtent,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() => _minute = index);
                    _emit();
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 60,
                    builder: (context, index) {
                      final selected = index == _minute;
                      return Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: selected
                              ? AppTextStyles.fastingFinishRowLabel
                              : AppTextStyles.fastingFinishPickerMuted,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _CurrentWeightCard extends StatelessWidget {
  const _CurrentWeightCard({
    required this.currentKg,
    required this.startKg,
    required this.goalKg,
    required this.progress,
    required this.onEdit,
  });

  final double currentKg;
  final double startKg;
  final double goalKg;
  final double progress;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Assets.images.weigher2.image(
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'fasting_page.finish_weight'.tr(),
                    style: AppTextStyles.caloriesCardTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatKg(currentKg),
                  style: AppTextStyles.homeWeightValue,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    'home.weight_unit'.tr(),
                    style: AppTextStyles.homeWeightUnit,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onEdit,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Assets.icons.solarPen2LineDuotone2.svg(
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            WeightProgressBar(progress: progress),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${'home.weight_start'.tr()} ',
                          style: AppTextStyles.homeWeightBoundLabel,
                        ),
                        TextSpan(
                          text:
                              '${_formatKg(startKg)}'
                              '${'home.weight_unit'.tr()}',
                          style: AppTextStyles.homeWeightBoundValue,
                        ),
                      ],
                    ),
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${'home.weight_target'.tr()} ',
                        style: AppTextStyles.homeWeightBoundLabel,
                      ),
                      TextSpan(
                        text:
                            '${_formatKg(goalKg)}'
                            '${'home.weight_unit'.tr()}',
                        style: AppTextStyles.homeWeightBoundValue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatKg(double kg) {
    if (kg == kg.roundToDouble()) return '${kg.toInt()}';
    return kg.toStringAsFixed(1);
  }
}
