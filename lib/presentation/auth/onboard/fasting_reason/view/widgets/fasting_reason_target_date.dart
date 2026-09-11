part of '../fasting_reason_view.dart';

/// Hedef tarih satırı — seçime göre güncellenir.
final class FastingReasonTargetDate extends StatelessWidget {
  const FastingReasonTargetDate({
    required this.dateLabel,
    super.key,
  });

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 2,
          color: ColorName.colorBlack.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'onboarding.target_date'.tr(),
              style: AppTextStyles.stepperLabel,
            ),
            Text(
              dateLabel,
              style: AppTextStyles.targetDateValue,
            ),
          ],
        ),
      ),
    );
  }
}
