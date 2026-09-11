part of '../entry_view.dart';

/// Mochi GIF + dumbbell + tartı kompozisyonu.
final class EntryHero extends StatelessWidget {
  const EntryHero({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final mascotSize = (width * 0.95).clamp(300.0, 420.0);

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Yoga mat
                Positioned(
                  bottom: height * 0.08,
                  child: Container(
                    width: mascotSize * 0.55,
                    height: 14,
                    decoration: BoxDecoration(
                      color: ColorName.colorMatGreen.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: ColorName.colorBlack.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                // Mascot
                Positioned(
                  bottom: height * 0.06,
                  child: Image.asset(
                    Assets.gifs.mascotWav.path,
                    width: mascotSize,
                    height: mascotSize,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
                // Dumbbell — üst sağ, saat yönünde 10°
                Positioned(
                  top: height * 0.02,
                  right: width * 0.02,
                  child: Transform.rotate(
                    angle: 10 * math.pi / 180,
                    child: Image.asset(
                      Assets.images.dumble.path,
                      width: width * 0.28,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Weigher — alt sol, saatin tersi 28°
                Positioned(
                  bottom: height * 0.02,
                  left: 0,
                  child: Transform.rotate(
                    angle: -28 * math.pi / 180,
                    child: Image.asset(
                      Assets.images.weigher.path,
                      width: width * 0.36,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
