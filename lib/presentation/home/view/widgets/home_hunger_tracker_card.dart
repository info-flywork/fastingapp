part of '../home_view.dart';

/// Home Hunger Tracker kartı — meal records'ın altında.
final class HomeHungerTrackerCard extends StatelessWidget {
  const HomeHungerTrackerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Assets.images.brain.image(
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'home.hunger_tracker'.tr(),
                  style: AppTextStyles.homeHungerTitle,
                ),
              ),
              Assets.icons.solarAltArrowUpLineDuotoneRight.svg(),
            ],
          ),
          const _HungerStrip(),
          const SizedBox(height: 16),
          Text(
            'home.hunger_question'.tr(),
            style: AppTextStyles.homeHungerQuestion,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'home.hunger_subtitle'.tr(),
            style: AppTextStyles.homeHungerSubtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'home.log_hunger'.tr(),
            onPressed: () {},
            decoration: AppButtonDecoration.homeJoin(),
            showIcon: false,
          ),
        ],
      ),
    );
  }
}

final class _HungerStrip extends StatelessWidget {
  const _HungerStrip();

  static const _stripH = 80.0;
  static const _stageH = 135.0;
  static const _mascotSize = 160.0;

  /// Bacakları stage altında kesmek için.
  static const _clipLegsBy = 25.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _stageH,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // #F9E9E6 | #E7F3E9 — Figma şerit (80h, radius 14)
          SizedBox(
            height: _stripH + 10,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: ColoredBox(color: Color(0xFFF9E9E6))),
                  Expanded(child: ColoredBox(color: Color(0xFFE7F3E9))),
                ],
              ),
            ),
          ),
          // burger + unhappy (beyaz kutu) | tongue (beyaz kutu) + brocc
          Positioned(
            left: 12,
            right: 12,
            bottom: (_stripH - 40) / 2 + 5,
            child: Row(
              children: [
                Assets.images.burgerv2.image(
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                _EmojiTile(
                  child: Assets.images.unhappyv2.image(
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(),
                _EmojiTile(
                  child: Assets.images.tonguev2.image(
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                Assets.images.broccv2.image(
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: -_clipLegsBy,
            child: IgnorePointer(
              child: Assets.images.hungerTracker.image(
                width: _mascotSize,
                height: _mascotSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sadece unhappy / tongue — 40×40 beyaz, radius 8, shadow.
final class _EmojiTile extends StatelessWidget {
  const _EmojiTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0C0C0D),
            offset: Offset(0, 1),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Color(0x1A0C0C0D),
            offset: Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
