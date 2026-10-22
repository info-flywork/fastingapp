import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/utils/extensions/future_extensions.dart';
import 'package:fastingapp/core/utils/weight_progress.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart'
    show SnackBarType;
import 'package:fastingapp/domain/user/user_repository.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_cubit.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/flip_clock_unit.dart';
import 'package:fastingapp/core/widgets/weight_progress_bar.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_first_time_view.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Oruç bitirme özeti sayfasına taşınan plan ve süre.
@immutable
final class FastingFinishArgs {
  const FastingFinishArgs({
    required this.fastId,
    required this.planTitle,
    required this.start,
    required this.end,
    this.targetMinutes,
  });

  final String fastId;
  final String planTitle;
  final DateTime start;
  final DateTime end;

  /// Orucun hedefi; bitiş planlanan bitişi 12 sa'ten fazla aşarsa onay
  /// sorulur (sunucu `LONG_OVERRUN` kuralı).
  final int? targetMinutes;
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

  late DateTime _start;
  late DateTime _end;
  var _editingStart = true;
  var _editingEnd = false;
  var _feeling = _FinishFeeling.superMood;
  var _saving = false;
  double? _currentKg;
  double? _startKg;
  double? _goalKg;
  double? _weightForSave;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _start = widget.args.start;
    _end = widget.args.end;
    unawaited(_loadWeight());
  }

  Future<void> _loadWeight() async {
    // Ana sayfa özeti zaten yüklüyse tekrar istenmez.
    final home = getIt<HomeBloc>().state;
    if (home is HomeLoaded && home.summary != null) {
      final summary = home.summary!;
      _currentKg = summary.weightCurrentKg;
      _startKg = summary.weightStartKg;
      _goalKg = summary.weightGoalKg;
      return;
    }
    try {
      final summary = await getIt<UserRepository>().getSummary();
      if (!mounted) return;
      setState(() {
        _currentKg = summary.weightCurrentKg;
        _startKg = summary.weightStartKg;
        _goalKg = summary.weightGoalKg;
      });
    } on Object {
      // Kilo kartı olmadan devam.
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Sayaç plan hedefini aşmaz: geç bitirilse de üst sınır planın saatidir.
  Duration get _elapsed {
    final diff = _end.difference(_start);
    if (diff.isNegative) return Duration.zero;
    final target = widget.args.targetMinutes;
    if (target != null && target > 0) {
      final cap = Duration(minutes: target);
      if (diff > cap) return cap;
    }
    return diff;
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
    final result = await AppDialogs.instance.showEditWeight(
      context,
      initialWeightKg: _currentKg ?? 70,
    );
    if (result == null || !mounted) return;
    setState(() {
      _currentKg = result.weightKg;
      _weightForSave = result.weightKg;
    });
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
    final startKg = _startKg;
    final currentKg = _currentKg;
    final goalKg = _goalKg;
    final progress = weightProgressOf(
      start: startKg,
      goal: goalKg,
      current: currentKg,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorBodyPageBg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                                    _start = _notFuture(value);
                                    // Bitiş başlangıçtan sonra ve şimdiden
                                    // ileri olmamalı.
                                    if (!_end.isAfter(_start)) {
                                      _end = _notFuture(
                                        _start.add(const Duration(hours: 16)),
                                      );
                                    }
                                  });
                                },
                                onEndChanged: (value) {
                                  setState(() {
                                    final end = _notFuture(value);
                                    _end = end.isAfter(_start)
                                        ? end
                                        : _start.add(
                                            const Duration(minutes: 1),
                                          );
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              if (currentKg != null &&
                                  startKg != null &&
                                  goalKg != null)
                                _CurrentWeightCard(
                                  currentKg: currentKg,
                                  startKg: startKg,
                                  goalKg: goalKg,
                                  progress: progress,
                                  onEdit: _editWeight,
                                ),
                              const SizedBox(height: 16),
                              _FeelingCard(
                                selected: _feeling,
                                onSelected: (value) {
                                  setState(() => _feeling = value);
                                },
                              ),
                              const SizedBox(height: 16),
                              _NotesCard(controller: _notesController),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _FinishBottomBar(
              bottomInset: math.max(bottom, 24),
              onSave: () => _onSave(context),
              onContinue: () => context.pop(false),
            ),
          ],
        ),
      ),
    );
  }

  static DateTime _notFuture(DateTime value) {
    final now = DateTime.now();
    return value.isAfter(now) ? now : value;
  }

  Future<void> _onSave(BuildContext context) async {
    if (_saving) return;
    final target = widget.args.targetMinutes;
    if (target != null) {
      final plannedEnd = _start.add(Duration(minutes: target));
      if (_end.difference(plannedEnd) > const Duration(hours: 12)) {
        final ok = await AppDialogs.instance.showLongOverrun(context);
        if (ok != true || !context.mounted) return;
      }
    }
    setState(() => _saving = true);
    final feeling = switch (_feeling) {
      _FinishFeeling.tough => 'tough',
      _FinishFeeling.meh => 'meh',
      _FinishFeeling.good => 'good',
      _FinishFeeling.superMood => 'super',
    };
    final result = await getIt<FastingSessionCubit>()
        .finishFast(
          fastId: widget.args.fastId,
          startedAt: _start,
          endedAt: _end,
          feeling: feeling,
          notes: _notesController.text.trim(),
          weightKg: _weightForSave,
        )
        .withLoading(context);
    if (!context.mounted) return;
    setState(() => _saving = false);
    if (result == null) {
      final msg = getIt<FastingSessionCubit>().state.errorMessage;
      if (msg != null) {
        AppSnackbar.show(
          context: context,
          text: msg,
          type: SnackBarType.failure,
        );
      }
      return;
    }
    if (result.isFirstFast) {
      final done = await context.pushNamed<bool>(
        RoutePaths.fastingFirstTime.name,
        extra: FastingFirstTimeArgs(elapsed: _elapsed),
      );
      if (!context.mounted) return;
      if (done ?? false) context.pop(true);
      return;
    }
    // Seri / XP / seviye / ada / meydan okuma (önceden hiç gösterilmiyordu).
    if (result.hasRewards) {
      await AppDialogs.instance.showFastReward(context, result: result);
      if (!context.mounted) return;
    }
    context.pop(true);
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
            child: AppImages.headerBack.image(
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),

          Positioned(
            left: 4,
            top: topInset,
            child: Transform.scale(
              scale: 1.1,
              child: AppImages.caloriesTracker.image(
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
        padding: const EdgeInsets.all(20),
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
                    child: AppImages.forkClosest.image(
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
            const SizedBox(height: 24),
            _TimeRow(
              positive: true,
              label: 'fasting_page.finish_start'.tr(),
              value: startLabel,
              onEdit: onToggleStart,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: editingStart
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        _InlineTimePicker(
                          initial: start,
                          onChanged: onStartChanged,
                        ),
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
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 20),
            Divider(
              height: 1,
              thickness: 1,
              color: ColorName.colorBlack.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 20),
            _TimeRow(
              positive: false,
              label: 'fasting_page.finish_end'.tr(),
              value: endLabel,
              onEdit: onToggleEnd,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: editingEnd
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        _InlineTimePicker(
                          initial: end,
                          onChanged: onEndChanged,
                        ),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
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
        Text(label, style: AppTextStyles.fastingFinishRowLabel),
        const Spacer(),
        Text(
          value,
          textAlign: TextAlign.end,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.fastingFinishRowValue,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onEdit,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: AppImages.solarPenBold1.image(
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
  static const _visibleCount = 3;
  // Sunucu kuralı: başlangıç/bitiş en fazla 7 gün geri, gelecekte değil.
  static const _pastDays = 7;
  static const _futureDays = 0;
  static const _hourCount = 24;
  static const _minuteCount = 60;
  static const _loopPasses = 40;

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
    final day = DateUtils.dateOnly(widget.initial);
    final found = _dates.indexWhere((d) => DateUtils.isSameDay(d, day));
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

  void _emit() {
    final day = _dates[_dateIndex];
    widget.onChanged(DateTime(day.year, day.month, day.day, _hour, _minute));
  }

  String _dateLabel(int index) {
    final day = _dates[index];
    if (DateUtils.isSameDay(day, DateTime.now())) {
      return 'fasting_page.start_sheet_today'.tr();
    }
    return DateFormat('d MMM EEE', context.locale.toString()).format(day);
  }

  int _signedOffset(int value, int selected, int count) {
    var delta = (value - selected) % count;
    final half = count ~/ 2;
    if (delta > half) delta -= count;
    if (delta < -half) delta += count;
    return delta;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _itemExtent * _visibleCount,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ColorName.colorFlipClock,
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
              child: const SizedBox(width: double.infinity, height: 40),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _FinishColumnWheel(
                  controller: _dateController,
                  childCount: _dates.length,
                  alignment: Alignment.centerRight,
                  labelAt: _dateLabel,
                  offsetAt: (index) => index - _dateIndex,
                  onSelected: (index) {
                    setState(() => _dateIndex = index);
                    _emit();
                  },
                ),
              ),
              const SizedBox(width: 56),
              SizedBox(
                width: 36,
                child: _FinishColumnWheel(
                  controller: _hourController,
                  childCount: _hourCount * _loopPasses,
                  labelAt: (index) =>
                      (index % _hourCount).toString().padLeft(2, '0'),
                  offsetAt: (index) =>
                      _signedOffset(index % _hourCount, _hour, _hourCount),
                  onSelected: (index) {
                    setState(() => _hour = index % _hourCount);
                    _emit();
                  },
                ),
              ),
              const SizedBox(width: 56),
              SizedBox(
                width: 36,
                child: _FinishColumnWheel(
                  controller: _minuteController,
                  childCount: _minuteCount * _loopPasses,
                  labelAt: (index) =>
                      (index % _minuteCount).toString().padLeft(2, '0'),
                  offsetAt: (index) => _signedOffset(
                    index % _minuteCount,
                    _minute,
                    _minuteCount,
                  ),
                  onSelected: (index) {
                    setState(() => _minute = index % _minuteCount);
                    _emit();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _FinishColumnWheel extends StatelessWidget {
  const _FinishColumnWheel({
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

  static const _itemExtent = 40.0;

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
          final offset = offsetAt(index);
          final selected = offset == 0;
          return Align(
            alignment: alignment,
            child: Text(
              labelAt(index),
              maxLines: 1,
              textAlign: TextAlign.center,
              style: selected
                  ? AppTextStyles.fastingFinishRowLabel
                  : AppTextStyles.fastingFinishPickerMuted,
            ),
          );
        },
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
                AppImages.weigher2.image(
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

enum _FinishFeeling { tough, meh, good, superMood }

final class _FeelingCard extends StatelessWidget {
  const _FeelingCard({required this.selected, required this.onSelected});

  final _FinishFeeling selected;
  final ValueChanged<_FinishFeeling> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppImages.goodColored.image(
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'fasting_page.finish_feeling'.tr(),
                    style: AppTextStyles.caloriesCardTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                for (final mood in _FinishFeeling.values)
                  Expanded(
                    child: _FeelingOption(
                      mood: mood,
                      selected: mood == selected,
                      onTap: () => onSelected(mood),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _FeelingOption extends StatelessWidget {
  const _FeelingOption({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final _FinishFeeling mood;
  final bool selected;
  final VoidCallback onTap;

  (AppImageAsset idle, AppImageAsset active, String labelKey) get _data =>
      switch (mood) {
        _FinishFeeling.tough => (
          AppImages.tough,
          AppImages.toughColored,
          'fasting_page.finish_tough',
        ),
        _FinishFeeling.meh => (
          AppImages.mehv3,
          AppImages.mehColored,
          'fasting_page.finish_meh',
        ),
        _FinishFeeling.good => (
          AppImages.goodv3,
          AppImages.goodColored,
          'fasting_page.finish_good',
        ),
        _FinishFeeling.superMood => (
          AppImages.superImage,
          AppImages.superColored,
          'fasting_page.finish_super',
        ),
      };

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final icon = selected ? data.$2 : data.$1;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          icon.image(width: 56, height: 56, fit: BoxFit.contain),
          const SizedBox(height: 8),
          Text(
            data.$3.tr(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: selected
                ? AppTextStyles.fastingFinishRowLabel
                : AppTextStyles.fastingFinishPickerMuted,
          ),
        ],
      ),
    );
  }
}

final class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppImages.greenBook.image(
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'fasting_page.finish_notes'.tr(),
                    style: AppTextStyles.caloriesCardTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 82,
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: AppTextStyles.fastingFinishRowLabel,
                cursorColor: ColorName.colorMealPositive,
                decoration: InputDecoration(
                  hintText: 'fasting_page.finish_notes_hint'.tr(),
                  hintStyle: AppTextStyles.fastingFinishNotesHint,
                  filled: true,
                  fillColor: ColorName.colorFlipClock,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma Frame 48096339 — üst radius 32, pad 16/16/24/16, gap 12.
final class _FinishBottomBar extends StatelessWidget {
  const _FinishBottomBar({
    required this.bottomInset,
    required this.onSave,
    required this.onContinue,
  });

  final double bottomInset;
  final VoidCallback onSave;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: 'fasting_page.finish_save'.tr(),
              onPressed: onSave,
              decoration: AppButtonDecoration.hungerResult(),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onContinue,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'fasting_page.finish_continue'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.fastingFinishContinue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
