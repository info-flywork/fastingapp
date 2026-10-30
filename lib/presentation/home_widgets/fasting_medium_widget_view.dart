import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Orta oruç widget'ı — başlık, kalan süre, plan ve mascot.
final class FastingMediumWidgetView extends StatelessWidget {
  const FastingMediumWidgetView({
    required this.headline,
    required this.timeLabel,
    required this.planLabel,
    this.live = false,
    super.key,
  });

  final String headline;
  final String timeLabel;
  final String planLabel;

  /// Canlı geri sayım: süre satırı boş, yerel kod çizer ([liveSpec]).
  final bool live;

  static const logicalSize = Size(310, 310);

  /// Canlı süre satırının en geniş hâli (soldan maskota kadar).
  static const _liveTextWidth = 124;

  /// Süre satırının konumu başlığın satır sayısına bağlı: başlık 258 px
  /// genişlikte ölçülür; satır üst 56 + başlık + 6, yazı 26 (yükseklik 1).
  /// Saniyeli sayaç ("7:33:31 kaldı") maskotun şapkasına taşmasın diye
  /// satır [_liveTextWidth] ile sınırlı; sığmazsa yerelde küçülür.
  static Map<String, Object> liveSpec(String headline, TextDirection dir) {
    final painter = TextPainter(
      text: TextSpan(text: headline, style: _headline),
      textDirection: dir,
    )..layout(maxWidth: logicalSize.width - 52);
    final top = 56 + painter.height + 6;
    painter.dispose();
    return {
      'w': 310,
      'h': 310,
      'tx': 26,
      'ty': top + 13,
      'ta': 'l',
      'ts': 26,
      'tw': _liveTextWidth,
      'tc': _hex(ColorName.colorSubtitle),
    };
  }

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
                  live: live,
                ),
              ),
              Positioned(
                right: -4,
                bottom: -48,
                child: AppImages.widget2.image(
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

final class _Copy extends StatelessWidget {
  const _Copy({
    required this.headline,
    required this.timeLabel,
    required this.planLabel,
    required this.live,
  });

  final String headline;
  final String timeLabel;
  final String planLabel;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(headline, style: _headline),
        const SizedBox(height: 6),
        Text(
          timeLabel,
          style: live ? _time.copyWith(color: Colors.transparent) : _time,
        ),
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

final class _Logo extends StatelessWidget {
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

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
