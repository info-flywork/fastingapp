part of '../home_view.dart';

/// Home üst bar: Premium CTA, streak, AI chat.
final class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    required this.streakDays,
    required this.isPremium,
    required this.onPremiumTapped,
    super.key,
  });

  final int streakDays;
  final bool isPremium;
  final VoidCallback onPremiumTapped;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          if (!isPremium) _PremiumPill(onTap: onPremiumTapped),
          const Spacer(),
          _StreakPill(streakDays: streakDays),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorName.colorWhite,
              boxShadow: [
                BoxShadow(
                  color: ColorName.colorBlack.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Assets.images.aiChat.image(
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

final class _PremiumPill extends StatelessWidget {
  const _PremiumPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
                bottomLeft: Radius.circular(4),
              ),
              gradient: const LinearGradient(
                colors: [
                  ColorName.colorPremiumGradientStart,
                  ColorName.colorPremiumGradientEnd,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorName.colorBlack.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              'home.get_premium'.tr(),
              style: AppTextStyles.homePremium,
            ),
          ),
          Positioned(
            top: -24,
            right: -6,
            child: Assets.images.proKing.image(
              width: 41,
              height: 41,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

final class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Assets.images.streakFlame.image(
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 6),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                ColorName.colorStreakGradientStart,
                ColorName.colorStreakGradientEnd,
              ],
            ).createShader(bounds),
            child: Text('$streakDays', style: AppTextStyles.homeStreakCount),
          ),
        ],
      ),
    );
  }
}
