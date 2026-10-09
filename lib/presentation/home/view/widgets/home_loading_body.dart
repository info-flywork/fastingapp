part of '../home_view.dart';

/// Home yükleniyor — kart yerleşimine uygun shimmer iskelet (full-page spinner yok).
final class HomeLoadingBody extends StatelessWidget {
  const HomeLoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AppShimmer(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppBottomNav.barClearance),
          children: const [
            _HomeShimmerTopBar(),
            _HomeShimmerWeekStrip(),
            AppShimmerBone(
              height: 168,
              borderRadius: BorderRadius.all(Radius.circular(20)),
              margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
            ),
            AppShimmerBone(
              height: 112,
              borderRadius: BorderRadius.all(Radius.circular(16)),
              margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
            ),
            _HomeShimmerMetrics(),
            AppShimmerBone(
              height: 148,
              borderRadius: BorderRadius.all(Radius.circular(16)),
              margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
            ),
            AppShimmerBone(
              height: 132,
              borderRadius: BorderRadius.all(Radius.circular(16)),
              margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
            ),
            AppShimmerBone(
              height: 168,
              borderRadius: BorderRadius.all(Radius.circular(16)),
              margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
            ),
            AppShimmerBone(
              height: 120,
              borderRadius: BorderRadius.all(Radius.circular(16)),
              margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
            ),
          ],
        ),
      ),
    );
  }
}

final class _HomeShimmerTopBar extends StatelessWidget {
  const _HomeShimmerTopBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          AppShimmerBone(
            width: 104,
            height: 32,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          Spacer(),
          AppShimmerBone(
            width: 72,
            height: 32,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          SizedBox(width: 10),
          AppShimmerBone(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ],
      ),
    );
  }
}

final class _HomeShimmerWeekStrip extends StatelessWidget {
  const _HomeShimmerWeekStrip();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            const Expanded(
              child: AppShimmerBone(
                height: 64,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

final class _HomeShimmerMetrics extends StatelessWidget {
  const _HomeShimmerMetrics();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: AppShimmerBone(
              height: 148,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: AppShimmerBone(
              height: 148,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}
