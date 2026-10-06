import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// İnternet yok sayfası. Uygulamanın üstünde tam ekran gösterilir
/// (OfflineGate); bağlantı gelince kendiliğinden kapanır.
///
/// Görsel uygulamaya gömülüdür (`tool/remote_images.json` → bundled):
/// internet yokken de görünür.
final class NoInternetView extends StatelessWidget {
  const NoInternetView({
    required this.isChecking,
    required this.onRetry,
    super.key,
  });

  final bool isChecking;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorName.colorWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Expanded(child: _SearchingMochi()),
              const SizedBox(height: 20),
              Text(
                'no_internet.title'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 32,
                  height: 40 / 32,
                  letterSpacing: -0.5,
                  color: ColorName.colorTitle,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'no_internet.subtitle'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                  height: 28 / 20,
                  letterSpacing: -0.5,
                  color: ColorName.colorSubtitle.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 64),
              AppButton(
                label: isChecking
                    ? 'no_internet.checking'.tr()
                    : 'no_internet.retry'.tr(),
                onPressed: isChecking ? () {} : onRetry,
                iconPosition: AppButtonIconPosition.leading,
                icon: isChecking
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: ColorName.colorWhite,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        size: 22,
                        color: ColorName.colorWhite,
                      ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Büyüteçle bağlantı arayan Mochi: yavaşça süzülür, arkasında sinyal
/// halkaları yayılır.
final class _SearchingMochi extends StatefulWidget {
  const _SearchingMochi();

  @override
  State<_SearchingMochi> createState() => _SearchingMochiState();
}

class _SearchingMochiState extends State<_SearchingMochi>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return AnimatedBuilder(
          animation: _clock,
          builder: (context, child) {
            final t = _clock.value;
            final float = math.sin(t * 2 * math.pi) * 8;
            return Stack(
              alignment: Alignment.center,
              children: [
                for (var i = 0; i < 3; i++) _ring(size, (t + i / 3) % 1),
                Transform.translate(offset: Offset(0, float), child: child),
              ],
            );
          },
          child: SizedBox.square(
            dimension: size * 0.78,
            child: AppImages.mascotSearch.image(fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  /// Merkezden dışa doğru büyüyüp sönen yeşil halka.
  Widget _ring(double size, double progress) {
    final eased = Curves.easeOut.transform(progress);
    return Opacity(
      opacity: (1 - progress) * 0.45,
      child: Container(
        width: size * (0.45 + 0.55 * eased),
        height: size * (0.45 + 0.55 * eased),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ColorName.colorCtaGradientBottom, width: 2),
        ),
      ),
    );
  }
}
