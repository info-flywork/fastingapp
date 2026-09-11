import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Highlight / success ara ekranı (yeşil veya özel gradient).
final class OnboardingHighlightView extends StatelessWidget {
  const OnboardingHighlightView({
    required this.mediaPath,
    required this.title,
    required this.subtitle,
    required this.middle,
    required this.buttonLabel,
    required this.onContinue,
    this.gradientColors = const [
      ColorName.colorHighlightGradientTop,
      ColorName.colorHighlightGradientBottom,
    ],
    super.key,
  });

  final String mediaPath;
  final String title;
  final Widget subtitle;
  final Widget middle;
  final String buttonLabel;
  final VoidCallback onContinue;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 40;
    final mediaSize = (width * 0.95).clamp(300.0, 420.0);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Spacer(),
                Image.asset(
                  mediaPath,
                  width: mediaSize,
                  height: mediaSize,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.highlightTitle,
                ),
                const SizedBox(height: 10),
                DefaultTextStyle(
                  style: AppTextStyles.highlightSubtitle,
                  textAlign: TextAlign.center,
                  child: subtitle,
                ),
                const SizedBox(height: 20),
                middle,
                const SizedBox(height: 60),
                AppButton(
                  label: buttonLabel,
                  onPressed: onContinue,
                  showIcon: false,
                  decoration: AppButtonDecoration.onLight(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
