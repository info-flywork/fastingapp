import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Orta oruç widget'ı — başlık, kalan süre, plan ve mascot.
final class FastingMediumWidgetView extends StatelessWidget {
  const FastingMediumWidgetView({
    required this.headline,
    required this.timeLabel,
    required this.planLabel,
    super.key,
  });

  final String headline;
  final String timeLabel;
  final String planLabel;

  static const logicalSize = Size(310, 310);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: logicalSize.width,
      height: logicalSize.height,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(40)),
        child: ColoredBox(
          color: ColorName.colorWhite,
          child: Stack(
            children: [
              const Positioned(top: 20, left: 26, child: _Logo()),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 56, 26, 16),
                child: _Copy(
                  headline: headline,
                  timeLabel: timeLabel,
                  planLabel: planLabel,
                ),
              ),
              Positioned(
                right: -4,
                bottom: -48,
                child: Assets.images.widget2.image(
                  height: 240,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Copy extends StatelessWidget {
  const _Copy({
    required this.headline,
    required this.timeLabel,
    required this.planLabel,
  });

  final String headline;
  final String timeLabel;
  final String planLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(headline, style: _headline),
        const SizedBox(height: 6),
        Text(timeLabel, style: _time),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: ColorName.colorFastingWidgetChip,
            borderRadius: BorderRadius.all(Radius.circular(99)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(planLabel, style: _chip),
          ),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        style: _logo,
        children: [
          TextSpan(
            text: 'Mochi',
            style: TextStyle(color: ColorName.colorTitle),
          ),
          TextSpan(
            text: 'Fast',
            style: TextStyle(color: ColorName.colorCtaGradientBottom),
          ),
        ],
      ),
    );
  }
}

const _logo = TextStyle(
  fontFamily: FontFamily.baloo,
  fontSize: 28,
  height: 24 / 28,
  letterSpacing: 28 * -0.015,
);

const _headline = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 44,
  height: 48 / 44,
  letterSpacing: -0.5,
  color: ColorName.colorTitle,
);

const _time = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 26,
  height: 1,
  color: ColorName.colorSubtitle,
);

const _chip = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 24,
  height: 1,
  color: ColorName.colorSubtitle,
);
