import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Highlight ekranlarındaki sosyal kanıt kartı ("1M+ …").
///
/// Metrik / caption parametreleriyle yeniden kullanılır; tamamen farklı
/// bir orta alan için [OnboardingHighlightView.middle]’a başka widget ver.
final class OnboardingSocialProofCard extends StatelessWidget {
  const OnboardingSocialProofCard({
    required this.metric,
    required this.caption,
    super.key,
  });

  final String metric;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(metric, style: AppTextStyles.socialProofMetric),
            const SizedBox(width: 10),
            Flexible(
              child: Text(caption, style: AppTextStyles.socialProofCaption),
            ),
          ],
        ),
      ),
    );
  }
}
