part of '../home_view.dart';

/// Home yüklendi durumu gövdesi.
///
/// [ListView.builder] ile yalnızca görünür (ve cache) widget'lar build edilir.
final class HomeLoadedBody extends StatelessWidget {
  const HomeLoadedBody({
    required this.user,
    required this.progress,
    required this.isPremium,
    required this.onPremiumTapped,
    required this.onChatTapped,
    required this.onWaterTapped,
    super.key,
  });

  final User user;
  final UserProgress progress;
  final bool isPremium;
  final VoidCallback onPremiumTapped;
  final VoidCallback onChatTapped;
  final VoidCallback onWaterTapped;

  static const _itemCount = 9;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: ListView.builder(
        physics: const ClampingScrollPhysics(),
        // Ekran dışındakiler tutulmasın; tekrar görünce yeniden build.
        addAutomaticKeepAlives: false,
        itemCount: _itemCount,
        itemBuilder: (context, index) => _buildItem(index),
      ),
    );
  }

  Widget _buildItem(int index) {
    return switch (index) {
      0 => HomeTopBar(
          streakDays: progress.streakDays > 0 ? progress.streakDays : 3,
          isPremium: isPremium,
          onPremiumTapped: onPremiumTapped,
          onChatTapped: onChatTapped,
        ),
      1 => const HomeWeekStrip(),
      2 => const HomeFastingCard(),
      3 => const HomeChallengeCard(),
      4 => HomeMetricCards(onWaterTapped: onWaterTapped),
      5 => const HomeWeightCard(),
      6 => const HomeMetabolicCard(),
      7 => const HomeMealRecordsCard(),
      8 => const HomeHungerTrackerCard(),
      _ => const SizedBox.shrink(),
    };
  }
}
