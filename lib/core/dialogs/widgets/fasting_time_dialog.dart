import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_time_picker.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Oruç / yemek penceresi saat seçimi sonucu.
@immutable
final class FastingTimeResult {
  const FastingTimeResult({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
}

/// Figma: Fasting Time — başlangıç / bitiş tekerlekleri + clock header.
final class FastingTimeDialog extends StatefulWidget {
  const FastingTimeDialog({
    required this.initialStartHour,
    required this.initialStartMinute,
    required this.initialEndHour,
    required this.initialEndMinute,
    this.titleKey = 'plans.fasting_time_title',
    this.startLabelKey = 'plans.fasting_time_start',
    this.endLabelKey = 'plans.fasting_time_finish',
    super.key,
  });

  /// Aynı iki saatli seçici başka ekranlarda da kullanılır (ör. uyku).
  final String titleKey;
  final String startLabelKey;
  final String endLabelKey;

  final int initialStartHour;
  final int initialStartMinute;
  final int initialEndHour;
  final int initialEndMinute;

  @override
  State<FastingTimeDialog> createState() => _FastingTimeDialogState();
}

class _FastingTimeDialogState extends State<FastingTimeDialog> {
  late int _startHour = widget.initialStartHour;
  late int _startMinute = widget.initialStartMinute;
  late int _endHour = widget.initialEndHour;
  late int _endMinute = widget.initialEndMinute;

  void _onSave() {
    Navigator.of(context).pop(
      FastingTimeResult(
        startHour: _startHour,
        startMinute: _startMinute,
        endHour: _endHour,
        endMinute: _endMinute,
      ),
    );
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
            padding: const EdgeInsets.only(top: 44),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ColorName.colorWhite,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.titleKey.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.weightDialogTitle,
                    ),
                    const SizedBox(height: 20),
                    OnboardingTimePicker(
                      label: widget.startLabelKey.tr(),
                      hour: _startHour,
                      minute: _startMinute,
                      onHourChanged: (h) => setState(() => _startHour = h),
                      onMinuteChanged: (m) => setState(() => _startMinute = m),
                    ),
                    const SizedBox(height: 16),
                    OnboardingTimePicker(
                      label: widget.endLabelKey.tr(),
                      hour: _endHour,
                      minute: _endMinute,
                      onHourChanged: (h) => setState(() => _endHour = h),
                      onMinuteChanged: (m) => setState(() => _endMinute = m),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'profile.save'.tr(),
                      onPressed: _onSave,
                      decoration: AppButtonDecoration.primary(),
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
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: ColorName.colorWhite,
                shape: BoxShape.circle,
                border: Border.all(color: ColorName.colorWhite, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: ColorName.colorBlack.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: AppImages.clock.image(fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
