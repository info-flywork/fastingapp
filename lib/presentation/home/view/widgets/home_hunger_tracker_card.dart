part of '../home_view.dart';

/// Home Hunger Tracker kartı — meal records'ın altında.
final class HomeHungerTrackerCard extends StatelessWidget {
  const HomeHungerTrackerCard({
    required this.onTap,
    this.physicalCount = 0,
    this.emotionalCount = 0,
    super.key,
  });

  final VoidCallback onTap;
  final int physicalCount;
  final int emotionalCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                AppImages.brain.image(
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
            _HungerStrip(
              physicalCount: physicalCount,
              emotionalCount: emotionalCount,
            ),
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
              onPressed: onTap,
              decoration: AppButtonDecoration.homeJoin(),
              showIcon: false,
            ),
          ],
        ),
      ),
    );
  }
}

final class _HungerStrip extends StatelessWidget {
  const _HungerStrip({
    required this.physicalCount,
    required this.emotionalCount,
  });

  final int physicalCount;
  final int emotionalCount;

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
                AppImages.burgerv2.image(
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                _EmojiTile(
                  count: physicalCount,
                  child: AppImages.unhappyv2.image(
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(),
                _EmojiTile(
                  count: emotionalCount,
                  child: AppImages.tonguev2.image(
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                AppImages.broccv2.image(
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
              child: AppImages.hungerTracker.image(
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
  const _EmojiTile({required this.child, this.count = 0});

  final Widget child;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
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
        ),
        if (count > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: ColorName.colorBrandStrong,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: AppTextStyles.homeMealTag.copyWith(
                  color: ColorName.colorWhite,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
