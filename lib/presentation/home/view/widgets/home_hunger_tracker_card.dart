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
          const SizedBox(height: 16),
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
  static const _stageH = 120.0;
  static const _mascotSize = 130.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _stageH,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: (_stageH - _stripH) / 2,
            height: _stripH,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: const Row(
                children: [
                  Expanded(
                    flex: 178,
                    child: ColoredBox(color: ColorName.colorMetabolicBg),
                  ),
                  Expanded(
                    flex: 196,
                    child: ColoredBox(color: ColorName.colorHungerGreen),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _IconTile(
                  child: Assets.images.burgerv2.image(
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                _IconTile(
                  child: Assets.images.unhappyv2.image(
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(),
                _IconTile(
                  child: Assets.images.tonguev2.image(
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                _IconTile(
                  child: Assets.images.broccv2.image(
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          IgnorePointer(
            child: Assets.images.hungerTracker.image(
              width: _mascotSize,
              height: _mascotSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma: 40×40, radius 8, beyaz + soft shadow.
final class _IconTile extends StatelessWidget {
  const _IconTile({required this.child});

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
