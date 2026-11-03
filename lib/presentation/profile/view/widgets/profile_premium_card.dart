part of '../profile_view.dart';

/// Premium CTA — Figma: #86B57F, r20, p16, gap20, border/inner shadow.
/// Mascot yukarı taşar (bildirim satırına binebilir); yazı/buton üstte.
final class ProfilePremiumCard extends StatelessWidget {
  const ProfilePremiumCard({required this.onGetPremium, super.key});

  final VoidCallback onGetPremium;

  static const _cardHeight = 168.0;
  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    // Layout sadece kart yüksekliği — üst boşluk yok; mascot Clip.none ile taşar.
    return InkWell(
      onTap: onGetPremium,
      borderRadius: BorderRadius.circular(99999),
      child: SizedBox(
        height: _cardHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_radius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: ColorName.colorPremiumCard),
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: const Alignment(0, 0.35),
                            colors: [
                              ColorName.colorWhite.withValues(alpha: 0.55),
                              ColorName.colorWhite.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(_radius),
                          border: Border.all(
                            color: ColorName.colorWhite.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              right: -55,
              bottom: -15,
              width: 248,
              height: _cardHeight + 100,
              child: IgnorePointer(
                child: AppImages.proReading.image(
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),

            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 100),
                      child: Text(
                        'profile.premium_title'.tr(),
                        style: AppTextStyles.profilePremiumTitle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 100),
                      child: Text(
                        'profile.premium_subtitle'.tr(),
                        style: AppTextStyles.profilePremiumSubtitle,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: Material(
                        color: ColorName.colorWhite,
                        borderRadius: BorderRadius.circular(99999),
                        child: Center(
                          child: Text(
                            'profile.get_premium'.tr(),
                            style: AppTextStyles.profileGetPremium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
