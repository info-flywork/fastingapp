import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_time_picker.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Meal Records tarih seçici sonucu (opsiyonel saat dahil).
@immutable
final class MealDatePickerResult {
  const MealDatePickerResult({required this.date});

  final DateTime date;
}

/// Öğün kayıtları tarih seçici — kompakt custom takvim.
///
/// [accentColor] verilirse seçili gün / bugün / onay CTA o renkte olur
/// (su / adım ekranları). Yoksa varsayılan yeşil CTA.
final class MealDatePickerDialog extends StatefulWidget {
  const MealDatePickerDialog({
    required this.initialDate,
    this.includeTime = false,
    this.accentColor,
    this.maxDaysBack,
    super.key,
  });

  final DateTime initialDate;
  final bool includeTime;

  /// Verilirse en fazla bu kadar gün geriye gidilir (öğün: sunucu 30 gün);
  /// yoksa 2 yıl.
  final int? maxDaysBack;
  final Color? accentColor;

  @override
  State<MealDatePickerDialog> createState() => _MealDatePickerDialogState();
}

class _MealDatePickerDialogState extends State<MealDatePickerDialog> {
  late DateTime _selected;
  late DateTime _displayedMonth;
  bool _yearPicker = false;

  static const _firstDateYearsBack = 2;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate;
    _selected = widget.includeTime ? initial : DateUtils.dateOnly(initial);
    _displayedMonth = DateTime(_selected.year, _selected.month);
  }

  DateTime get _today => DateUtils.dateOnly(DateTime.now());
  DateTime get _firstDate {
    final days = widget.maxDaysBack;
    if (days != null) return _today.subtract(Duration(days: days));
    return DateTime(_today.year - _firstDateYearsBack);
  }

  DateTime get _lastDate => _today;

  void _onConfirm() {
    // Saatli seçimde gelecek saat olmaz (bugün seçilip ileri saat).
    final now = DateTime.now();
    final date = widget.includeTime && _selected.isAfter(now) ? now : _selected;
    Navigator.of(context).pop(MealDatePickerResult(date: date));
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_displayedMonth.year, _displayedMonth.month + delta);
    final firstMonth = DateTime(_firstDate.year, _firstDate.month);
    final lastMonth = DateTime(_lastDate.year, _lastDate.month);
    if (next.isBefore(firstMonth) || next.isAfter(lastMonth)) return;
    setState(() {
      _displayedMonth = next;
      _yearPicker = false;
    });
  }

  void _onDayTap(DateTime day) {
    final dateOnly = DateUtils.dateOnly(day);
    if (dateOnly.isAfter(_lastDate) || dateOnly.isBefore(_firstDate)) return;
    setState(() {
      _selected = DateTime(
        day.year,
        day.month,
        day.day,
        _selected.hour,
        _selected.minute,
      );
    });
  }

  void _onYearTap(int year) {
    var next = DateTime(year, _displayedMonth.month);
    final firstMonth = DateTime(_firstDate.year, _firstDate.month);
    final lastMonth = DateTime(_lastDate.year, _lastDate.month);
    if (next.isBefore(firstMonth)) next = firstMonth;
    if (next.isAfter(lastMonth)) next = lastMonth;
    setState(() {
      _displayedMonth = next;
      _yearPicker = false;
    });
  }

  void _onHourChanged(int hour) {
    setState(() {
      _selected = DateTime(
        _selected.year,
        _selected.month,
        _selected.day,
        hour,
        _selected.minute,
      );
    });
  }

  void _onMinuteChanged(int minute) {
    setState(() {
      _selected = DateTime(
        _selected.year,
        _selected.month,
        _selected.day,
        _selected.hour,
        minute,
      );
    });
  }

  Color get _accent => widget.accentColor ?? ColorName.colorCtaGradientBottom;

  Color get _accentTop => widget.accentColor ?? ColorName.colorCtaGradientTop;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final locale = context.locale.toString();
    final selectedLabel = widget.includeTime
        ? DateFormat.yMMMMd(locale).add_jm().format(_selected)
        : DateFormat.yMMMMd(locale).format(DateUtils.dateOnly(_selected));
    final accent = _accent;
    final buttonDecoration = widget.accentColor != null
        ? AppButtonDecoration.accent(accent)
        : AppButtonDecoration.primary();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: GestureDetector(
          onTap: () {},
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 36),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ColorName.colorWhite,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.includeTime
                                ? 'meal_detail.pick_date_time'.tr()
                                : 'meal_records_page.pick_date'.tr(),
                            style: AppTextStyles.mealRecordsDateTitle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedLabel,
                            style: TextStyle(
                              fontFamily: FontFamily.sFProDisplay,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              height: 20 / 14,
                              color: ColorName.colorSubtitle.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: ColorName.colorBodyPageBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                10,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _MonthHeader(
                                    title: DateFormat.yMMMM(
                                      locale,
                                    ).format(_displayedMonth),
                                    yearPickerOpen: _yearPicker,
                                    canGoPrev:
                                        DateTime(
                                          _displayedMonth.year,
                                          _displayedMonth.month,
                                        ).isAfter(
                                          DateTime(
                                            _firstDate.year,
                                            _firstDate.month,
                                          ),
                                        ),
                                    canGoNext:
                                        DateTime(
                                          _displayedMonth.year,
                                          _displayedMonth.month,
                                        ).isBefore(
                                          DateTime(
                                            _lastDate.year,
                                            _lastDate.month,
                                          ),
                                        ),
                                    onTitleTap: () => setState(
                                      () => _yearPicker = !_yearPicker,
                                    ),
                                    onPrev: () => _shiftMonth(-1),
                                    onNext: () => _shiftMonth(1),
                                  ),
                                  const SizedBox(height: 10),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    alignment: Alignment.topCenter,
                                    child: _yearPicker
                                        ? _YearGrid(
                                            selectedYear: _displayedMonth.year,
                                            firstYear: _firstDate.year,
                                            lastYear: _lastDate.year,
                                            accent: accent,
                                            onYearTap: _onYearTap,
                                          )
                                        : Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _WeekdayRow(
                                                localizations: localizations,
                                              ),
                                              const SizedBox(height: 6),
                                              _DayGrid(
                                                month: _displayedMonth,
                                                selected: _selected,
                                                today: _today,
                                                firstDate: _firstDate,
                                                lastDate: _lastDate,
                                                localizations: localizations,
                                                accent: accent,
                                                accentTop: _accentTop,
                                                onDayTap: _onDayTap,
                                              ),
                                            ],
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (widget.includeTime) ...[
                            const SizedBox(height: 12),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: ColorName.colorBodyPageBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  12,
                                  12,
                                  8,
                                ),
                                child: OnboardingTimePicker(
                                  label: 'meal_detail.pick_time'.tr(),
                                  hour: _selected.hour,
                                  minute: _selected.minute,
                                  onHourChanged: _onHourChanged,
                                  onMinuteChanged: _onMinuteChanged,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'meal_records_page.confirm_date'.tr(),
                            onPressed: _onConfirm,
                            decoration: buttonDecoration,
                            showIcon: false,
                            fontSize: 16,
                          ),
                        ],
                      ),
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
                  alignment: Alignment.center,
                  child: Assets.icons.solarCalendarMarkLineDuotone.svg(
                    width: 32,
                    height: 32,
                    colorFilter: ColorFilter.mode(
                      widget.accentColor ?? ColorName.colorTitle,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.title,
    required this.yearPickerOpen,
    required this.canGoPrev,
    required this.canGoNext,
    required this.onTitleTap,
    required this.onPrev,
    required this.onNext,
  });

  final String title;
  final bool yearPickerOpen;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback onTitleTap;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onTitleTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: FontFamily.sFProDisplay,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 20 / 15,
                        color: ColorName.colorTitle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    turns: yearPickerOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: ColorName.colorTitle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _NavChip(
          icon: Icons.chevron_left_rounded,
          onTap: canGoPrev ? onPrev : null,
        ),
        const SizedBox(width: 6),
        _NavChip(
          icon: Icons.chevron_right_rounded,
          onTap: canGoNext ? onNext : null,
        ),
      ],
    );
  }
}

final class _NavChip extends StatelessWidget {
  const _NavChip({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: ColorName.colorWhite,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? ColorName.colorTitle
                : ColorName.colorSubtitle.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

final class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.localizations});

  final MaterialLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[];
    for (
      var i = localizations.firstDayOfWeekIndex;
      labels.length < 7;
      i = (i + 1) % 7
    ) {
      labels.add(localizations.narrowWeekdays[i]);
    }

    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: SizedBox(
              height: 20,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: FontFamily.sFProDisplay,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1,
                    color: ColorName.colorSubtitle.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

final class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.month,
    required this.selected,
    required this.today,
    required this.firstDate,
    required this.lastDate,
    required this.localizations,
    required this.accent,
    required this.accentTop,
    required this.onDayTap,
  });

  final DateTime month;
  final DateTime selected;
  final DateTime today;
  final DateTime firstDate;
  final DateTime lastDate;
  final MaterialLocalizations localizations;
  final Color accent;
  final Color accentTop;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstOfMonth = DateTime(month.year, month.month);
    final weekdayOffset =
        (firstOfMonth.weekday - localizations.firstDayOfWeekIndex) % 7;

    final cells = <Widget?>[];
    for (var i = 0; i < weekdayOffset; i++) {
      cells.add(null);
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      cells.add(
        _DayCell(
          day: day,
          isSelected: DateUtils.isSameDay(date, selected),
          isToday: DateUtils.isSameDay(date, today),
          enabled: !date.isBefore(firstDate) && !date.isAfter(lastDate),
          accent: accent,
          accentTop: accentTop,
          onTap: () => onDayTap(date),
        ),
      );
    }

    final rows = <TableRow>[];
    for (var i = 0; i < cells.length; i += 7) {
      final slice = List<Widget?>.from(
        cells.sublist(i, (i + 7).clamp(0, cells.length)),
      );
      while (slice.length < 7) {
        slice.add(null);
      }
      rows.add(
        TableRow(
          children: [
            for (final cell in slice)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: SizedBox(
                  height: 36,
                  child: cell ?? const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      );
    }

    return Table(children: rows);
  }
}

final class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.enabled,
    required this.accent,
    required this.accentTop,
    required this.onTap,
  });

  final int day;
  final bool isSelected;
  final bool isToday;
  final bool enabled;
  final Color accent;
  final Color accentTop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg;
    Decoration? decoration;

    if (!enabled) {
      fg = ColorName.colorSubtitle.withValues(alpha: 0.28);
    } else if (isSelected) {
      fg = ColorName.colorWhite;
      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accentTop, accent],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      );
    } else if (isToday) {
      fg = accent;
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 1.5),
      );
    } else {
      fg = ColorName.colorTitle;
    }

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 34,
            height: 34,
            decoration: decoration,
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontFamily: FontFamily.sFProDisplay,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w600
                      : FontWeight.w500,
                  fontSize: 14,
                  height: 1,
                  color: fg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _YearGrid extends StatelessWidget {
  const _YearGrid({
    required this.selectedYear,
    required this.firstYear,
    required this.lastYear,
    required this.accent,
    required this.onYearTap,
  });

  final int selectedYear;
  final int firstYear;
  final int lastYear;
  final Color accent;
  final ValueChanged<int> onYearTap;

  @override
  Widget build(BuildContext context) {
    final years = [for (var y = lastYear; y >= firstYear; y--) y];

    return SizedBox(
      height: 168,
      child: GridView.count(
        physics: const ClampingScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (final year in years)
            Material(
              color: year == selectedYear ? accent : ColorName.colorWhite,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onYearTap(year),
                child: Center(
                  child: Text(
                    '$year',
                    style: TextStyle(
                      fontFamily: FontFamily.sFProDisplay,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: year == selectedYear
                          ? ColorName.colorWhite
                          : ColorName.colorTitle,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
